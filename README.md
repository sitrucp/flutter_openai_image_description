# Flutter OpenAI Image Description App

This is a simple Flutter Android app that uses OpenAI ChatGPT-4-Vision API to get descriptions of images on mobile device. Use cases include:

* Get a description of a photo
* Get insights from a screenshot of a chart eg line chart of real vs nominal hourly wages
* Get explanation from a screenshot of a meme visualization eg you've seen elf on a shelf, have you seen ... (vader on a tater)

The app stores the following data in the app's device folder in a JSON file:

* Encrypted API key
* Image file name
* Device folder path
* Prompt text
* Response text
* Response datetime string
* Tokens used value
* Estimated cost value

You need to provide your own OpenAI API key which is entered in the app's Settings page.

<strong>App screenshots</strong> (click to zoom in)

Allow Permissions - allow app to access device folders

<img src="app_screenshots/frame_desc_image/010-permissions_frame_desc.png" alt="enter_api_key" width="20%"/>

Enter API Key - saved in JSON file in Android app folder

<img src="app_screenshots/frame_desc_image/020-enter api key_frame_desc.png" alt="enter_api_key" width="20%"/>

Select folder - select any accessible folder that contains images

<img src="app_screenshots/frame_desc_image/030-select folder_frame_desc.png" alt="thumbnails" width="20%"/>

<img src="app_screenshots/frame_desc_image/040-select folder_frame_desc.png" alt="thumbnails" width="20%"/>

Selected folder images - blue bordered images have at least one response

<img src="app_screenshots/frame_desc_image/090-image gallery_frame_desc.png" alt="thumbnails" width="20%"/>

Selected image prompt - modify text prompt as desired, default to low resolution (good enough for  most) but can optionally send higher resolution image then tap Get Response button

<img src="app_screenshots/frame_desc_image/060-image detail_frame_desc.png" alt="image prompt" width="20%"/>

Selected image prompt response - view response

<img src="app_screenshots/frame_desc_image/070-image detail_frame_desc.png" alt="image prompt response 1" width="20%"/>

Selected image prompt response - copy, share or delete response

<img src="app_screenshots/frame_desc_image/080-image detail_frame_desc.png" alt="image prompt response 2" width="20%"/>

## Acknowledgments

ChatGPT-4