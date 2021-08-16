# Friendly Potato Stream
A stream overlay tool for Twitch and Youtube (not yet implemented).

## Quickstart
Fill in your user details in `export/potato-config.json`. This file is stored locally and thus never requires the user to input their details in the program directly. Run the app.

During export, put `potato-config.json` in the same directory as your executable.

See the Twitch api docs for more information on some of these keys.
```
{
    "username": "your_twitch_username",
    "token": "your_generated_access_token",
    "join_channel": "you_twitch_username_again",
    "channel_id": "your_channel_id",
    "nonce": "some_somewhat_unique_text_for_response_verification",
    "client_id": "your_twitch_app_client_id",
    "client_secret": "your_twitch_app_client_secret"
}
```

## Discussion
A Discord server [is available here](https://discord.gg/6mcdWWBkrr) if you need help, like to contribute, or just want to chat.

