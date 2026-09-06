const imageInput = document.getElementById("imageInput");
const imagePreview = document.getElementById("imagePreview");
const uploadContent = document.getElementById("uploadContent");
const fileName = document.getElementById("fileName");
const analyzeBtn = document.getElementById("analyzeBtn");


// When the user selects an image
imageInput.addEventListener("change", function () {

    const file = this.files[0];

    if (!file) return;

    // Show the file name
    fileName.textContent = file.name;

    // Create image preview
    const imageURL = URL.createObjectURL(file);

    imagePreview.src = imageURL;
    imagePreview.style.display = "block";

    // Hide upload text
    uploadContent.style.display = "none";

    // Enable Analyze button
    analyzeBtn.disabled = false;
});


// Analyze button clicked
analyzeBtn.addEventListener("click", function () {

    // Change button while "analyzing"
    analyzeBtn.textContent = "ANALYZING...";
    analyzeBtn.disabled = true;

    // Simulate AI analysis for now
    setTimeout(function () {

        alert(
            "Analysis Complete!\n\n" +
            "Image Quality: Good\n" +
            "DR Severity: Moderate NPDR\n" +
            "Confidence: 91.4%\n" +
            "Referable DR: Yes"
        );

        analyzeBtn.textContent = "ANALYZE RETINA →";
        analyzeBtn.disabled = false;

    }, 2000);

});