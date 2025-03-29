<?php
$to = 'edward@manimatorstudio.com';
$subject = 'Reserva de auditorio ';
$message = 'Nombre:' . $_POST["name"] . "\n";
echo $message;exit;
$message .= 'Email:' . $_POST["your_email"] . "\n";
$message .= 'Telefono:' . $_POST["your_phone"] . "\n";
$message .= 'Comments:' . $_POST["your_comments"] . "\n";
$headers = 'From: ' . $_POST['email'] . "\r\n" .
    'Reply-To: ' . $_POST['email'] . "\r\n" .
    'X-Mailer: PHP/' . phpversion();
mail ($to, $subject, $message, $headers);
header("Location: http://www.fucsalud.edu.co/biblioteca");
?>