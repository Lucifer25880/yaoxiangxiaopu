<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.io.*, com.fasterxml.jackson.databind.ObjectMapper, com.fasterxml.jackson.core.type.TypeReference" %>
<%
    // [原有的数据加载和游戏逻辑代码保持不变...]
    // 从herbs.json加载药材数据
    List<Map<String, String>> herbs = new ArrayList<>();
    try {
        String realPath = application.getRealPath(request.getServletPath());
        String herbsJsonPath = realPath.replace("game.jsp", "herbs.json");

        try (BufferedReader br = new BufferedReader(new FileReader(herbsJsonPath))) {
            StringBuilder json = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                json.append(line);
            }
            ObjectMapper objectMapper = new ObjectMapper();
            herbs = objectMapper.readValue(json.toString(), new TypeReference<List<Map<String, String>>>() {});

            // 按药材名称拼音排序
            Collections.sort(herbs, new Comparator<Map<String, String>>() {
                @Override
                public int compare(Map<String, String> o1, Map<String, String> o2) {
                    return o1.get("name").compareTo(o2.get("name"));
                }
            });
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    if (herbs.isEmpty()) {
        throw new IllegalStateException("药材数据为空，请检查 herbs.json 文件是否正确加载。");
    }

    // 初始化或获取当前客人编号(1-12)
    Integer currentGuest = (Integer) session.getAttribute("currentGuest");
    if (currentGuest == null) {
        currentGuest = new Random().nextInt(12) + 1;
        session.setAttribute("currentGuest", currentGuest);
    }

    // 客人需求
    Map<String, String> guestRequest = new HashMap<>();
    if (session.getAttribute("guestRequest") == null) {
        Random random = new Random();
        Map<String, String> randomHerb = herbs.get(random.nextInt(herbs.size()));
        guestRequest.put("description", randomHerb.get("description"));
        guestRequest.put("correctHerb", randomHerb.get("name"));
        session.setAttribute("guestRequest", guestRequest);
    } else {
        guestRequest = (Map<String, String>) session.getAttribute("guestRequest");
    }

    // 错误次数
    int errors = 0;
    if (session.getAttribute("errors") != null) {
        errors = (int) session.getAttribute("errors");
    }

    // 检查玩家选择
    String selectedHerb = request.getParameter("herb");
    if (selectedHerb != null) {
        if (selectedHerb.equals(guestRequest.get("correctHerb"))) {
            // 正确选择，切换到下一位客人
            currentGuest = currentGuest % 12 + 1;
            session.setAttribute("currentGuest", currentGuest);
            session.removeAttribute("guestRequest");
            session.removeAttribute("errors");
            response.sendRedirect("game.jsp");
        } else {
            errors++;
            session.setAttribute("errors", errors);
            if (errors >= 3) {
                session.setAttribute("showErrorPopup", true);
                response.sendRedirect("game.jsp");
                return;
            }
        }
    }

    // 检查是否需要显示错误弹窗
    Boolean showErrorPopup = (Boolean) session.getAttribute("showErrorPopup");
    if (showErrorPopup != null && showErrorPopup) {
        session.removeAttribute("showErrorPopup");
        session.invalidate();
    }

    // 检查是否显示药典
    String showHerbBook = request.getParameter("showHerbBook");
    String selectedHerbDetail = request.getParameter("selectedHerbDetail");
%>

<!DOCTYPE html>
<html>
<head>
    <title>药香小铺 - 游戏</title>
    <style>
        body {
            font-family: 'SimHei', sans-serif;
            background-color: #f5f5dc;
            margin: 0;
            padding: 0;
            height: 100vh;
            overflow: hidden;
            position: relative;
        }

        /* 整体布局 */
        .game-container {
            display: grid;
            grid-template-areas:
                "shelf guest"
                "counter counter";
            grid-template-rows: 70% 30%;
            grid-template-columns: 70% 30%;
            height: 100vh;
        }

        /* 药柜架子区域 */
        .herb-shelf {
            grid-area: shelf;
            background-color: #8B4513;
            border-right: 10px solid #5D4037;
            position: relative;
            overflow: hidden;
            display: flex;
        }

        .shelf-container {
            display: flex;
            flex-direction: column;
            width: 100%;
            height: 100%;
            padding: 15px;
            box-sizing: border-box;
            overflow-y: auto;
        }

        .shelf-row {
            display: flex;
            flex-wrap: wrap;
            justify-content: flex-start;
            gap: 10px;
            padding: 5px;
        }

        .herb-item {
            width: calc(12.5% - 10px);
            min-width: 100px;
            height: 150px;
            background-color: #D2B48C;
            border: 3px solid #A0522D;
            border-radius: 10px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s;
            box-sizing: border-box;
        }

        .herb-item:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }

        .herb-item img {
            width: 80px;
            height: 80px;
            object-fit: contain;
        }

        .herb-item p {
            margin: 5px 0 0;
            color: #5D4037;
            font-weight: bold;
            text-align: center;
            font-size: 14px;
        }

        /* 客人区域 */
        .guest-area {
            grid-area: guest;
            background-color: #D7CCC8;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 20px;
            border-left: 5px solid #8D6E63;
        }

        .guest-bubble {
            background-color: white;
            padding: 15px;
            border-radius: 20px;
            margin-bottom: 20px;
            position: relative;
            max-width: 80%;
        }

        .guest-bubble:after {
            content: '';
            position: absolute;
            bottom: -15px;
            left: 50%;
            border-width: 15px 15px 0;
            border-style: solid;
            border-color: white transparent transparent;
            transform: translateX(-50%);
        }

        .guest-image {
            width: 300px;
            height: 450px;
            background-size: contain;
            background-repeat: no-repeat;
            background-position: center;
        }

        /* 柜台区域 */
        .counter {
            grid-area: counter;
            background-color: #A0522D;
            border-top: 15px solid #5D4037;
            display: flex;
            align-items: center;
            justify-content: flex-start;
            position: relative;
        }

        .counter-top {
            position: absolute;
            top: -10px;
            width: 100%;
            height: 10px;
            background-color: #8B4513;
        }

        .counter-content {
            color: white;
            text-align: center;
            margin-left: 700px; /* 给药典留出空间 */
        }

        /* 药典书区域 - 修改为放在柜台左侧 */
        .herb-book {
            position: absolute;
            left: 30px;
            bottom: 60px;
            background-color: #5D4037;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s;
            z-index: 10;
            width: 100px;
            height: 130px;
        }

        .herb-book:hover {
            transform: translateY(-5px);
        }

        .herb-book-cover {
            width: 80px;
            height: 100px;
            background-color: #8B4513;
            border: 5px solid #5D4037;
            border-radius: 5px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: space-around;
            color: #FFD700;
            font-weight: bold;
            box-shadow: 3px 3px 10px rgba(0,0,0,0.5);
            position: relative;
            overflow: hidden;
        }

        .book-title {
            font-size: 24px;
            writing-mode: vertical-rl;
            text-orientation: upright;
            letter-spacing: 5px;
            margin-top: 10px;
        }

        .book-subtitle {
            font-size: 20px;
            writing-mode: vertical-rl;
            text-orientation: upright;
            letter-spacing: 5px;
        }

        .book-decoration {
            position: absolute;
            bottom: 5px;
            right: 5px;
            font-size: 12px;
            color: #D32F2F;
        }

        /* 添加一些古风装饰效果 */
        .herb-book-cover:before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, transparent 45%, rgba(255,215,0,0.1) 45%, rgba(255,215,0,0.1) 55%, transparent 55%);
        }

        /* 药典展开样式 */
        .herb-book-popup {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.7);
            display: none;
            justify-content: center;
            align-items: center;
            z-index: 100;
        }

        .herb-book-popup.show {
            display: flex;
        }

        .herb-book-content {
            width: 80%;
            height: 80%;
            background-color: #f5f5dc;
            border-radius: 10px;
            border: 15px solid #8B4513;
            display: flex;
            overflow: hidden;
            box-shadow: 0 0 20px rgba(0,0,0,0.5);
        }

        .herb-book-sidebar {
            width: 30%;
            background-color: #D2B48C;
            padding: 20px;
            overflow-y: auto;
            border-right: 3px solid #8B4513;
        }

        .herb-book-sidebar h2 {
            color: #5D4037;
            text-align: center;
            margin-bottom: 20px;
            border-bottom: 2px solid #8B4513;
            padding-bottom: 10px;
        }

        .herb-book-list {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }

        .herb-book-item {
            padding: 8px;
            background-color: #f5f5dc;
            border: 1px solid #8B4513;
            border-radius: 5px;
            cursor: pointer;
            text-align: center;
            transition: all 0.3s;
        }

        .herb-book-item:hover {
            background-color: #8B4513;
            color: white;
        }

        .herb-book-item.active {
            background-color: #5D4037;
            color: white;
        }

        .herb-book-main {
            width: 70%;
            padding: 20px;
            overflow-y: auto;
            position: relative;
        }

        .herb-book-close {
            position: absolute;
            top: 10px;
            right: 10px;
            background-color: #5D4037;
            color: white;
            border: none;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            font-size: 16px;
            cursor: pointer;
        }

        .herb-detail {
            display: none;
        }

        .herb-detail.active {
            display: block;
        }

        .herb-detail h3 {
            color: #5D4037;
            border-bottom: 2px solid #8B4513;
            padding-bottom: 10px;
        }

        .herb-detail-image {
            width: 200px;
            height: 200px;
            margin: 20px auto;
            display: block;
            object-fit: contain;
            border: 3px solid #8B4513;
            border-radius: 5px;
        }

        /* 自定义滚动条 */
        .shelf-container::-webkit-scrollbar,
        .herb-book-sidebar::-webkit-scrollbar,
        .herb-book-main::-webkit-scrollbar {
            width: 12px;
        }

        .shelf-container::-webkit-scrollbar-track,
        .herb-book-sidebar::-webkit-scrollbar-track,
        .herb-book-main::-webkit-scrollbar-track {
            background: #5D4037;
            border-radius: 6px;
        }

        .shelf-container::-webkit-scrollbar-thumb,
        .herb-book-sidebar::-webkit-scrollbar-thumb,
        .herb-book-main::-webkit-scrollbar-thumb {
            background-color: #D2B48C;
            border-radius: 6px;
            border: 2px solid #5D4037;
        }

        /* 错误提示 */
        .error-count {
            position: absolute;
            top: 10px;
            right: 10px;
            background-color: #D32F2F;
            color: white;
            padding: 5px 10px;
            border-radius: 50%;
            font-weight: bold;
        }

        /* 错误弹窗 */
        .error-popup {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.7);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 100;
        }

        .error-popup-content {
            background-color: #f5f5dc;
            padding: 30px;
            border-radius: 10px;
            border: 3px solid #8B4513;
            max-width: 400px;
            text-align: center;
            box-shadow: 0 0 20px rgba(0,0,0,0.5);
        }

        .error-popup h2 {
            color: #D32F2F;
            margin-top: 0;
        }

        .error-popup-button {
            background-color: #8B4513;
            color: white;
            border: none;
            padding: 10px 20px;
            margin-top: 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }

        .error-popup-button:hover {
            background-color: #A0522D;
        }
    </style>
</head>
<body>
<% if (showErrorPopup != null && showErrorPopup) { %>
<div class="error-popup" id="errorPopup">
    <div class="error-popup-content">
        <h2>温馨提示</h2>
        <p>你为你的客人挑选错所需药品次数过多，你好像还需要精进</p>
        <button class="error-popup-button" onclick="redirectToIndex()">返回学习</button>
    </div>
</div>
<% } %>

<div class="game-container">
    <!-- 药柜架子区域 -->
    <div class="herb-shelf">
        <div class="shelf-container" id="shelfContainer">
            <div class="shelf-row">
                <% for(int i=0; i<herbs.size(); i++) { %>
                <div class="herb-item" onclick="selectHerb('<%= herbs.get(i).get("name") %>')">
                    <img src="<%= herbs.get(i).get("image") %>" alt="<%= herbs.get(i).get("name") %>">
                    <p><%= herbs.get(i).get("name") %></p>
                </div>
                <% } %>
            </div>
        </div>
    </div>

    <!-- 客人区域 -->
    <div class="guest-area">
        <div class="guest-bubble">
            <p>我需要的药好像是这样的：<%= guestRequest.get("description") %></p>
        </div>
        <div class="guest-image" style="background-image: url('images/guest<%= currentGuest %>.png')"></div>
    </div>

    <!-- 柜台区域 -->
    <div class="counter">
        <div class="counter-top"></div>
        <!-- 药典书区域 - 现在放在柜台左侧 -->
        <div class="herb-book" onclick="showHerbBook()">
            <div class="herb-book-cover">
                <div class="book-title">药</div>
                <div class="book-subtitle">典</div>
                <div class="book-decoration">✿</div>
            </div>
        </div>

        <div class="counter-content">
            <h2>药香小铺</h2>
            <p>请从药柜中选择客人需要的药材</p>
        </div>
        <div class="error-count">错误: <%= errors %></div>
    </div>
</div>

<!-- 药典弹窗 -->
<div class="herb-book-popup <%= showHerbBook != null ? "show" : "" %>" id="herbBookPopup">
    <div class="herb-book-content">
        <button class="herb-book-close" onclick="hideHerbBook()">×</button>
        <div class="herb-book-sidebar">
            <h2>药材目录</h2>
            <div class="herb-book-list">
                <% for(int i=0; i<herbs.size(); i++) {
                    String herbName = herbs.get(i).get("name");
                    String activeClass = herbName.equals(selectedHerbDetail) ? "active" : "";
                    if(selectedHerbDetail == null && i == 0) activeClass = "active";
                %>
                <div class="herb-book-item <%= activeClass %>"
                     onclick="showHerbDetail('<%= herbName %>')">
                    <%= herbName %>
                </div>
                <% } %>
            </div>
        </div>
        <div class="herb-book-main">
            <% for(int i=0; i<herbs.size(); i++) {
                Map<String, String> herb = herbs.get(i);
                String showClass = herb.get("name").equals(selectedHerbDetail) ? "active" : "";
                if(selectedHerbDetail == null && i == 0) showClass = "active";
            %>
            <div class="herb-detail <%= showClass %>" id="detail-<%= herb.get("name") %>">
                <h3><%= herb.get("name") %></h3>
                <img src="<%= herb.get("image") %>" alt="<%= herb.get("name") %>" class="herb-detail-image">
                <p><strong>描述：</strong><%= herb.get("description") %></p>
                <p><strong>知识：</strong><%= herb.get("knowledge") %></p>
            </div>
            <% } %>
        </div>
    </div>
</div>

<script>
    // 药材选择函数
    function selectHerb(herbName) {
        window.location.href = "game.jsp?herb=" + encodeURIComponent(herbName);
    }

    // 返回首页
    function redirectToIndex() {
        window.location.href = "index.jsp";
    }

    // 显示药典
    function showHerbBook() {
        window.location.href = "game.jsp?showHerbBook=true";
    }

    // 隐藏药典
    function hideHerbBook() {
        window.location.href = "game.jsp";
    }

    // 显示药材详情
    function showHerbDetail(herbName) {
        window.location.href = "game.jsp?showHerbBook=true&selectedHerbDetail=" + encodeURIComponent(herbName);
    }

    <% if (showErrorPopup != null && showErrorPopup) { %>
    setTimeout(redirectToIndex, 5000); // 5秒后自动跳转
    <% } %>
</script>
</body>
</html>