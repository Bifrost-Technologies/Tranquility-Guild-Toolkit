# Tranquility Discord mirror — existing bot setup

This is an optional extension of the existing Discord companion, not a required addon dependency. No credentials are bundled. Existing local credentials are currently blank, so capture/posting cannot run until the owner configures them locally. Do not paste tokens into a chat or addon field.

Target supplied by the guild owner:

- Invite: https://discord.gg/CMjbSRYt6
- Server: Tranquility Server / 1570745250148909216
- Public general channel: 1570745250958282803, addon alias general

## Bot configuration

The companion source includes mirror.mjs and mirror.test.mjs plus hooks in the existing bot/commands. It keeps the existing opportunity commands. Copy the owner app's bot token/application ID into its local .env, set its desired GUILD_ID, and invite the bot to Tranquility with View Channel, Read Message History and Send Messages. No Administrator permission is required.

Enable Message Content intent for this bot in Discord's developer portal, then set DISCORD_MIRROR_ENABLED=1 locally. Leave it 0 to retain the original bot without message capture. Register commands and start the bot through its existing npm scripts. Do not start a second competing bot instance. Registration modifies the owner app's commands only when the owner explicitly runs it.

A server manager can use /titan mirror-channel alias:general channel:#general and /titan mirror-status. The public #general ID is preconfigured. Additional aliases require explicit public channel configuration; private channels, threads, other servers and DMs are rejected. Bots' messages are excluded from capture, and replies disable mentions.

## Discord → WoW

The bot writes data/discord-to-wow.txt as a non-executable plain-text snapshot. In the addon: open Discord lounge, save the exact trusted relay character and allowed aliases, then the officer pastes the snapshot into the transfer box and clicks Import. Members running the addon receive it over the guild addon channel. There is no live external socket in WoW and no silent rewriting of a running SavedVariable.

## WoW → Discord

Members queue replies in the lounge; they remain marked not posted. The officer clicks Copy relay reply export, reviews it, saves that text in the bot's data/wow-replies-approved.txt, and explicitly runs /titan mirror-post-replies as a server manager. Only these explicitly approved replies are sent. The bot preserves native WoW sender attribution from the relay export, disables pings and deduplicates sends.

After actual Discord send success, import data/discord-reply-acks.txt in the addon to mark matching replies Posted. A failed/ambiguous send is not automatically repeated; inspect Discord and the bot's mirror-state.json before resolving it. Do not manufacture acknowledgements. Addon reply identity depends on trusting the officer/export; it is not account-linking or cryptographic authentication.

Snapshots retain the latest 120 bounded messages and clip long content for the addon packet budget. They are snapshots, not full Discord history or live edit/delete sync. Capture requires an online authorized bot and manual officer handoff. The interface works for guild members without a personal Discord account once their relay imports messages.

## Validation

Run node --test in the companion directory. Test with a non-sensitive public post, a guild reply, actual Discord send acknowledgement, a duplicate import, an unauthorized relay and a denied private channel. Verify the app's intents/permissions and command availability before enabling capture. No Discord message has been posted automatically during this preparation.