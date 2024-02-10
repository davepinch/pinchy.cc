---
title: "mamake"
layout: empty
license: public domain
tags:
  - generative work
---
{{< rawhtml >}}
<style>
    body, html {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        overflow: hidden; /* Prevent scrollbars */
    }
    
    canvas {
        display: block;
        background: #eee; /* Optional background color for visualization */
        width: 100%;
        height: 100%;
    }
</style>        

<canvas id="myCanvas"></canvas>

<script language="javascript">
const canvas = document.getElementById('myCanvas');
const ctx = canvas.getContext('2d');

const cellSize = 32; // 32x32 cells
let colors = []; // To store cell colors

function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    // Resize the colors array to match new canvas size
    colors = Array(Math.ceil(canvas.width / cellSize)).fill(0).map(() => Array(Math.ceil(canvas.height / cellSize)).fill("#FFFFFF"));

    fillCells();
}

function getRandomColor() {
    const letters = '0123456789ABCDEF';
    let color = '#';
    for (let i = 0; i < 6; i++) {
        color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
}

function getAverageColor(x, y) {
    let redSum = 0, greenSum = 0, blueSum = 0, count = 0;

    for (let i = -1; i <= 1; i++) {
        for (let j = -1; j <= 1; j++) {
            if (i === 0 && j === 0) continue; // skip the center cell
            const xi = x + i;
            const yj = y + j;

            if (xi >= 0 && yj >= 0 && xi < colors.length && yj < colors[xi].length) {
                const color = colors[xi][yj];
                redSum += parseInt(color.substr(1, 2), 16);
                greenSum += parseInt(color.substr(3, 2), 16);
                blueSum += parseInt(color.substr(5, 2), 16);
                count++;
            }
        }
    }

    const avgRed = Math.round(redSum / count).toString(16).padStart(2, '0');
    const avgGreen = Math.round(greenSum / count).toString(16).padStart(2, '0');
    const avgBlue = Math.round(blueSum / count).toString(16).padStart(2, '0');

    return `#${avgRed}${avgGreen}${avgBlue}`;
}

function fillCells() {
    const horizontalCells = Math.ceil(canvas.width / cellSize);
    const verticalCells = Math.ceil(canvas.height / cellSize);

    for (let x = 0; x < horizontalCells; x++) {
        for (let y = 0; y < verticalCells; y++) {
            const color = getRandomColor();
            colors[x][y] = color;
            ctx.fillStyle = color;
            ctx.fillRect(x * cellSize, y * cellSize, cellSize, cellSize);
        }
    }
}

const SPECIAL_COLOR_PROBABILITY = 500; // 1 out of 5 times
const SPECIAL_COLOR = "#FF0000"; // pure red

function handleEvent(event) {
    // Prevent scrolling on mobile when touching the canvas
    event.preventDefault();

    let x, y;

    if (event.type === 'mousemove') {
        x = event.clientX;
        y = event.clientY;
    } else if (event.type === 'touchmove') {
        x = event.touches[0].clientX;
        y = event.touches[0].clientY;
    }

    const cellX = Math.floor(x / cellSize);
    const cellY = Math.floor(y / cellSize);

    const randomNumber = Math.floor(Math.random() * SPECIAL_COLOR_PROBABILITY);
    const colorToUse = (randomNumber === 0) ? getRandomColor() : getAverageColor(cellX, cellY);

    ctx.fillStyle = colorToUse;
    ctx.fillRect(cellX * cellSize, cellY * cellSize, cellSize, cellSize);

    // Update the color in our tracking array
    colors[cellX][cellY] = colorToUse;
}

canvas.addEventListener('mousemove', handleEvent);
canvas.addEventListener('touchmove', handleEvent);

// Initial resize and fill
resizeCanvas();

// Resize the canvas and refill cells every time the window is resized
window.addEventListener('resize', resizeCanvas);

</script>
{{< /rawhtml >}}
