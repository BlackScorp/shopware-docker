#!/usr/bin/env php
<?php

$ollamaUrl = "http://llm:11434/api/generate";
$model = "qwen2.5-coder:1.5b";

$systemPrompt = file_get_contents(__DIR__ . "/base-prompt.md");

$context = "";

function askLLM($prompt, $model, $url)
{
    $data = [
        "model" => $model,
        "prompt" => $prompt,
        "stream" => false
    ];

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/json"]);

    $response = curl_exec($ch);
    curl_close($ch);

    $json = json_decode($response, true);

    return trim($json['response'] ?? '');
}

function runTool($tool)
{
    switch ($tool['tool']) {

        case 'read_file':
            return file_get_contents($tool['path']) ?: "file not readable";

        case 'list_dir':
            return shell_exec("ls -la " . escapeshellarg($tool['path']));

        case 'find_files':
            return shell_exec(
                "find " .
                escapeshellarg($tool['path']) .
                " -name " .
                escapeshellarg($tool['pattern'])
            );

        case 'finish':
            return $tool['message'];

        default:
            return "unknown tool";
    }
}

echo "Agent gestartet\n";

while (true) {

    echo "\n> ";
    $userInput = trim(fgets(STDIN));

    $loopContext = "User: $userInput\n";

    while (true) {

        $prompt =
            $systemPrompt .
            "\n\nConversation:\n" .
            $context .
            "\n" .
            $loopContext;

        $response = askLLM($prompt, $model, $ollamaUrl);

        echo "\nLLM RAW:\n$response\n";

        $tool = json_decode($response, true);

        if (!$tool) {
            echo "Invalid JSON from LLM\n";
            break;
        }

        if ($tool['tool'] === 'finish') {

            echo "\nAI:\n" . $tool['message'] . "\n";

            $context .= "\nUser: $userInput\nAssistant: " . $tool['message'] . "\n";

            break;
        }

        $result = runTool($tool);

        echo "\n[Tool Result]\n$result\n";

        $loopContext .=
            "Tool Call: " . json_encode($tool) . "\n" .
            "Tool Result:\n" . $result . "\n";
    }
}