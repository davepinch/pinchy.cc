---
title: "I am sorry for offending you."
url: /i-am-sorry-for-offending-you/
---
{{< rawhtml >}}
<div id="apology">
    <p id="apology-text">I am sorry for offending you.</p>
    <p id="satisfaction-question">Are you satisfied with this apology?</p>

    <!-- hACK -->
    <form method="get" action="/how-satisfied-are-you/'">
        <button type="submit">
            Yes, I am satisfied.
        </button>
    </form>
    <button id="no-button">No, I am still offended.</button>

</div>

<script>
    const apologies = [
        "I am sorry for offending you.",
        "I am <i>really</i> sorry for offending you.",
        "I am <b>sorry</b> for offending you.",
        "I am <b>double</b> sorry for offending you!!",
        "I am <b>triple</b> sorry for offending you!!!",
        "I am <b>quadruple</b> sorry for offending you!!!!",
        "I am <b>quintuple</b> sorry for offending you!!!!!",
        "I am <b>sextuple</b> sorry for offending you!!!!!!",
        "I am <b>septuple</b> sorry for offending you!!!!!!!",
        "I am <b>octuple</b> sorry for offending you!!!!!!!!",
        "I am <b>nonuple</b> sorry for offending you!!!!!!!!!",
        "I am <span style='font-size: 10pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 20pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 30pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 50pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 80pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 130pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 210pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 340pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 550pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 890pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 1440pt'>sorry</span> for offending you.",
        "I am <span style='font-size: 2330pt'>sorry</span> for offending you.",
        "There's just no pleasing you."
    ];

    let currentApologyIndex = 0;

    function displayApology() {
        const apologyText = document.getElementById("apology-text");
        apologyText.innerHTML = apologies[currentApologyIndex];
    }

    function handleNoClick() {
        currentApologyIndex = (currentApologyIndex + 1) % apologies.length;
        displayApology();
    }

    const noButton = document.getElementById("no-button");
    noButton.addEventListener("click", handleNoClick);

    displayApology();

</script>
{{< /rawhtml >}}