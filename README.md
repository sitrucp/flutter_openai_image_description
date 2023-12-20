# Flutter OpenAI Image Description App

This is a simple Android Flutter app that uses OpenAI ChatGPT-4-Vision API to get descriptions of screenshots on mobile device. 

For example, create screenshot of a Tweet chart or meme and send it to OpenAI to get a description or answer questions about the image contents. 

Prompts and responses are saved in JSON file along with tokens used and estimated cost.

Rename lib/config_template.dart to config.dart template.

You need to provide your own OpenAI API key. 

<strong>App screenshots</strong>

Enter API Key - saved in JSON file in Android app folder
![Enter API and select folder](app_screenshots/enter_api_key.jpg.png)

Selected folder image thumbnails - blue bordered images have at least one response
![Enter API and select folder](app_screenshots/thumbnails.jpg)

Selected image prompt - modify text prompt as desired, default to low resolution (good enough for  most)
![Enter API and select folder](app_screenshots/prompt.jpg.jpg.png)

Selected image prompt response 1 - can get more than response each with diffirent prompt or resolution
![Enter API and select folder](app_screenshots/response_2.jpg)

Selected image prompt response 2
![Enter API and select folder](app_screenshots/response_2.jpg)