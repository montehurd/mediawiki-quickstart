<?php

wfLoadExtension( 'ContactPage' );
$wgContactConfig['default'] = array(
    'RecipientUser' => 'Username',  # Change 'Username' to the actual username of the recipient
    'SenderName' => 'Wiki contact form',  # Name for outgoing email
    'SenderEmail' => null,  # Defaults to $wgPasswordSender
    'RequiresInfo' => true,  # Whether or not to require real name & email
    'DisplayFormat' => 'table',  # Format to display form fields
    'IncludeIP' => true,  # Whether to pass & record the submitting user's IP address
    'MustBeLoggedIn' => false,  # Whether user must be logged in to use the contact form
    'AdditionalFields' => array(),
    # ... other configuration options ...
);
