---
title: "However complex, they always found the pattern."
next: "The bosses noticed and offered a promotion."
---

{{<rawhtml>}}
<style>
  .button-container {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 10px;
  }
  .button {
    padding: 10px;
    font-size: 18px;
    text-align: center;
    background-color: lightblue;
    border: none;
    cursor: pointer;
  }
  .button.disabled {
    background-color: lightgray;
    cursor: not-allowed;
  }
</style>
<div class="button-container">
  <button class="button" onclick="toggleRandom()">0</button>
  <button class="button" onclick="toggleRandom()">1</button>
  <button class="button" onclick="toggleRandom()">2</button>
  <button class="button" onclick="toggleRandom()">3</button>
  <button class="button" onclick="toggleRandom()">4</button>
  <button class="button" onclick="toggleRandom()">5</button>
  <button class="button" onclick="toggleRandom()">6</button>
  <button class="button" onclick="toggleRandom()">7</button>
  <button class="button" onclick="toggleRandom()">8</button>
  <button class="button" onclick="toggleRandom()">9</button>
  <button class="button" onclick="toggleRandom()">A</button>
  <button class="button" onclick="toggleRandom()">B</button>
  <button class="button" onclick="toggleRandom()">C</button>
  <button class="button" onclick="toggleRandom()">D</button>
  <button class="button" onclick="toggleRandom()">E</button>
  <button class="button" onclick="toggleRandom()">F</button>
</div>

<script>
function toggleRandom() {
  const buttons = document.querySelectorAll('.button');
  let disabledCount = 0;
  buttons.forEach(button => {
    if (Math.random() > 0.5) {
      button.classList.remove('disabled');
      button.disabled = false;
    } else {
      button.classList.add('disabled');
      button.disabled = true;
      disabledCount++;
    }
  });
  
  if (disabledCount === buttons.length) {
    alert("Pattern found!");
  }
}
</script>
{{</rawhtml>}}