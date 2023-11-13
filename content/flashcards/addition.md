---
title: "Addition Flashcard"
date: 2023-10-08
type: flashcard
tags:
  - addition
  - flashcard
---
<!DOCTYPE html>
<html>
<head>
  <title>Addition Flashcard</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f2f2f2;
    }
    h1 {
      text-align: center;
      margin-top: 50px;
      font-size: 48px;
      color: #333;
    }
    .container {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin-top: 50px;
    }
    .card {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 400px;
      height: 300px;
      background-color: #fff;
      border-radius: 10px;
      box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.2);
      margin-bottom: 50px;
    }
    .card h2 {
      font-size: 72px;
      color: #333;
      margin: 0;
    }
    .card input[type="number"] {
      font-size: 48px;
      padding: 10px;
      border-radius: 5px;
      border: none;
      text-align: center;
      margin-top: 50px;
      width: 200px;
      outline: none;
    }
    .card button {
      font-size: 24px;
      padding: 10px 20px;
      background-color: #333;
      color: #fff;
      border: none;
      border-radius: 5px;
      margin-top: 50px;
      cursor: pointer;
      outline: none;
    }
    .card button:hover {
      background-color: #555;
    }
  </style>
</head>
<body>
  <h1>Addition Flashcard</h1>
  <div class="container">
    <div class="card">
      <h2 id="num1"></h2>
      <h2>+</h2>
      <h2 id="num2"></h2>
      <input type="number" id="answer" placeholder="Enter answer">
      <button onclick="checkAnswer()">Check Answer</button>
    </div>
  </div>
  <script>
    let num1, num2;
    const urlParams = new URLSearchParams(window.location.search);
    const values = urlParams.getAll('values');
    if (values.length === 0) {
      num1 = Math.floor(Math.random() * 90) + 10;
      num2 = Math.floor(Math.random() * 90) + 10;
    } else if (values.length === 1) {
      num1 = parseInt(values[0]);
      num2 = 0;
    } else {
      num1 = parseInt(values[0]);
      num2 = parseInt(values[1]);
    }
    document.getElementById("num1").innerHTML = num1;
    document.getElementById("num2").innerHTML = num2;
    function checkAnswer() {
      const answer = parseInt(document.getElementById("answer").value);
      const correctAnswer = num1 + num2;
      if (answer === correctAnswer) {
        alert("Correct!");
      } else {
        alert("Incorrect. The correct answer is " + correctAnswer);
      }
    }
  </script>
</body>
</html>
