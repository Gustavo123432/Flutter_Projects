<?php
	
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header('Content-Type: application/json');


// Check for errors and ensure it's a POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $_POST['query_param'] == 10) {
    // Check if the "image" and "id" parameters are set in the POST data
    if (isset($_POST['image']) && isset($_POST['id'])) {
        // Get the base64 image data and id
        $base64Image = $_POST['image'];
        $id = $_POST['id'];

        // Decode the base64 image data
        $imageData = base64_decode($base64Image);

        // Check if decoding was successful
        if ($imageData === false) {
            // Return an error response if decoding fails
            echo json_encode(['success' => false, 'message' => 'Error decoding base64 image']);
            exit; // Terminate script execution
        }

        // Generate a unique filename using the provided id
        $filename = $id . '.png';

        // Specify the path where you want to save the image
        $filePath = 'C:/Inetpub/vhosts/interagit.com/services.interagit.com/App_Data/TesteImagens/' . $filename;

        // Save the image to the specified path
        if (file_put_contents($filePath, $imageData) === false) {
            // Return an error response if saving fails
            echo json_encode(['success' => false, 'message' => 'Error saving image']);
            exit; // Terminate script execution
        }

        // Return a success response with the file path
        echo json_encode(['success' => true, 'message' => 'Image saved successfully', 'file_path' => $filename]);
    } else {
        // Return an error response if "image" or "id" parameters are not set
        echo json_encode(['success' => false, 'message' => 'Image or ID parameter is missing']);
    }
} else {
    // Return an error response for non-POST requests or invalid query_param
    echo json_encode(['success' => false, 'message' => 'Invalid request method or query_param']);
}
?>
