# Flutter OpenAI Image Description App

This is a simple Flutter Android app that uses OpenAI ChatGPT-4-Vision API to get descriptions of images on mobile device. Use cases include:

* Get a description of a photo.
* Get insights from a screenshot of a chart eg line chart of real vs nominal hourly wages.
* Get explanation from a screenshot of a meme visualization eg you've seen elf on a shelf, have you seen ... (vader on a tater).

Persistent storage of response data in device app folder JSON file. Can have multiple different prompt and response for same image. Data stored:

* Prompt
* Response
* Response datetime
* Tokens used
* Estimated cost

View the code on <a href="https://github.com/sitrucp/flutter_openai_image_description">Github</a>.

After opening the project in IDE with Flutter Android development environment setup:

* Rename lib/config_template.dart to config.dart template.
* You need to provide your own OpenAI API key. 

<strong>App screenshots</strong> (click to zoom in)

Enter API Key - saved in JSON file in Android app folder

<img src="app_screenshots/enter_api_key.jpg" alt="enter_api_key" width="20%"/>

Selected folder image thumbnails - blue bordered images have at least one response

<img src="app_screenshots/thumbnails.jpg" alt="thumbnails" width="20%"/>

Selected image prompt - modify text prompt as desired, default to low resolution (good enough for  most) but can optionally send higher resolution image.

<img src="app_screenshots/prompt.jpg" alt="image prompt" width="20%"/>

Selected image prompt response 1 - can get more than one response each with different prompt and/or resolution

<img src="app_screenshots/response_1.jpg" alt="image prompt response 1" width="20%"/>

Selected image prompt response 2

<img src="app_screenshots/response_2.jpg" alt="image prompt response 2" width="20%"/>

## Acknowledgments

ChatGPT-4-Turbo