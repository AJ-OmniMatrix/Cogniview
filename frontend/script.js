const imageInput = document.getElementById("imageInput");
const imagePreview = document.getElementById("imagePreview");
const uploadContent = document.getElementById("uploadContent");
const fileName = document.getElementById("fileName");
const analyzeBtn = document.getElementById("analyzeBtn");

const resultsDashboard = document.getElementById("resultsDashboard");
const resultOriginalImage = document.getElementById("resultOriginalImage");
const newAnalysisBtn = document.getElementById("newAnalysisBtn");

let uploadedImageURL = "";


// =========================
// IMAGE UPLOAD
// =========================

imageInput.addEventListener("change", function () {

    const file = this.files[0];

    if (!file) return;

    // Show filename
    fileName.textContent = file.name;

    // Create image URL
    uploadedImageURL = URL.createObjectURL(file);

    // Show preview on upload page
    imagePreview.src = uploadedImageURL;
    imagePreview.style.display = "block";

    // Hide upload instructions
    uploadContent.style.display = "none";

    // Enable analyze button
    analyzeBtn.disabled = false;
});


// =========================
// ANALYZE IMAGE
// =========================

analyzeBtn.addEventListener("click", function () {

    // Show analyzing state
    analyzeBtn.textContent = "ANALYZING...";
    analyzeBtn.disabled = true;

    // Simulate AI analysis for now
    setTimeout(function () {

        // Put the uploaded image in the results dashboard
        resultOriginalImage.src = uploadedImageURL;

        // Show results dashboard
        resultsDashboard.classList.add("active");

        // Scroll smoothly to results
        resultsDashboard.scrollIntoView({
            behavior: "smooth",
            block: "start"
        });

        // Restore button
        analyzeBtn.textContent = "ANALYZE RETINA →";
        analyzeBtn.disabled = false;

    }, 2000);

});


// =========================
// NEW ANALYSIS
// =========================

newAnalysisBtn.addEventListener("click", function () {

    // Hide results
    resultsDashboard.classList.remove("active");

    // Reset file input
    imageInput.value = "";

    // Reset preview
    imagePreview.src = "";
    imagePreview.style.display = "none";

    // Show upload instructions again
    uploadContent.style.display = "block";

    // Reset filename
    fileName.textContent = "No image selected";

    // Disable analyze button
    analyzeBtn.disabled = true;

    // Clear stored image
    uploadedImageURL = "";

    // Scroll back to top
    window.scrollTo({
        top: 0,
        behavior: "smooth"
    });

});