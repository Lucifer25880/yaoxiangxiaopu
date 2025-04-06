<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
  <title>药香小铺</title>
  <style>
    body {
      font-family: 'SimHei', sans-serif;
      background-color: #f5f5dc;
      color: #333;
      margin: 0;
      padding: 0;
      position: relative;
      overflow: hidden;
    }

    .background-shelves {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-image: url('images/shelves.png');
      background-size: cover;
      background-position: center;
      background-repeat: no-repeat;
      z-index: -1;
      opacity: 0.5;
      filter: sepia(50%) brightness(110%);
    }

    .container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      position: relative;
      z-index: 1;
      background-color: rgba(245, 245, 220, 0.7);
      padding-top: 50px;
    }

    .title {
      font-size: 3em;
      color: #8b4513;
      margin-bottom: 20px;
      text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
    }

    .description {
      font-size: 1.2em;
      color: #555;
      margin-bottom: 40px;
      text-align: center;
      max-width: 80%;
      line-height: 1.6;
      background-color: rgba(255, 255, 255, 0.7);
      padding: 15px;
      border-radius: 8px;
    }

    .start-button {
      font-size: 1.5em;
      padding: 10px 20px;
      background-color: #8b4513;
      color: #fff;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      transition: all 0.3s;
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
      margin-bottom: 30px;
    }

    .start-button:hover {
      background-color: #a0522d;
      transform: translateY(-3px);
      box-shadow: 0 6px 12px rgba(0, 0, 0, 0.3);
    }

    .apprentice {
      width: 200px;
      height: 300px;
      position: relative;
      overflow: hidden;
      border-radius: 100px;
      box-shadow: 0 0 15px rgba(0, 0, 0, 0.6);
      margin-bottom: 50px;
      background-color: rgba(0, 0, 0, 0.2);
    }

    .apprentice video {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  </style>
</head>
<body>
<!-- 全屏背景药柜 -->
<div class="background-shelves"></div>

<div class="container">
  <div class="title">药香小铺</div>
  <div class="description">你是一位中药店的老板，快来为客人挑选正确的药材吧！</div>
  <a href="game.jsp" class="start-button">开始学习</a>
  <div class="apprentice">
    <video autoplay loop muted>
      <source src="images/apprentice.mp4" type="video/mp4">
      Your browser does not support the video tag.
    </video>
  </div>
</div>
</body>
</html>