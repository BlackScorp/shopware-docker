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
        case 'project_tree':
            return buildProjectTree('/var/www/html');

        case 'search_code':

            $query = escapeshellarg($tool['query']);
            $path = escapeshellarg($tool['path'] ?? '/var/www/html');

            $cmd = "rg --line-number --no-heading --color never --max-columns 200 $query $path";
                    echo $cmd;
            return shell_exec($cmd);
        case 'finish':
            return $tool['message'];

        default:
            return "unknown tool";
    }
}

function buildProjectTree($root)
{
    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::SELF_FIRST
    );

    $paths = [];

    foreach ($iterator as $file) {

        $path = str_replace($root . '/', '', $file->getPathname());

        if ($file->isDir()) {
            $paths[] = $path . "/";
        } else {
            $paths[] = $path;
        }
    }

    return implode("\n", $paths);
}

function extractJson($text)
{
    // markdown codeblock entfernen
    $text = preg_replace('/```json|```/', '', $text);

    // erstes JSON Objekt finden
    if (preg_match('/\{.*\}/s', $text, $m)) {
        return $m[0];
    }

    return null;
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

       $json = extractJson($response);

        if (!$json) {
            echo "No JSON found\n";
            break;
        }

        $tool = json_decode($json, true);
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