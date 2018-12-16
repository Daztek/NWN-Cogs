#include "inc_nwncogs"

void main()
{
    struct NWNX_Redis_PubSubMessageData data = NWNX_Redis_GetPubSubMessageData();

    if( NWNCogs_GetIsValidBotCommand(NWNCOGS_CHANNEL_INCOMING_COMMANDS_PLAYER, data) )
    {
        struct NWNCogs_DiscordEmbed discordEmbed = NWNCogs_DiscordEmbed_Full(
                                                                        GetName(GetModule()),
                                                                        "https://i.imgur.com/k7AyXCD.png",
                                                                        "'" + data.message + "' Response",
                                                                        RandomName(NAME_FIRST_GENERIC_MALE) + RandomName(NAME_LAST_HUMAN),
                                                                        NWNCogs_RBGToDiscordColor(Random(256), Random(256), Random(256)),
                                                                        "",
                                                                        "https://i.imgur.com/k7AyXCD.png",
                                                                        "Sent from my NWServer",
                                                                        "https://i.imgur.com/k7AyXCD.png"
            );

            NWNCogs_PublishDiscordResponse_Embed(NWNCOGS_CHANNEL_OUTGOING_RESPONSE_PLAYER, discordEmbed);
    }
    else
    if( NWNCogs_GetIsValidBotCommand(NWNCOGS_CHANNEL_INCOMING_COMMANDS_ADMIN, data) )
    {
        NWNCogs_PublishDiscordResponse_Simple(NWNCOGS_CHANNEL_OUTGOING_RESPONSE_ADMIN, "NWServer Admin Command: '" + data.message + "'");
    }
}