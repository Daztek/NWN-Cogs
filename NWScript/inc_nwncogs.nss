#include "nwnx_redis"
#include "nwnx_redis_ps"

/*
    NWNCogs Functions
    Repository: https://github.com/Daztek/NWN-Cogs
*/

const string NWNCOGS_CHANNEL_INCOMING_COMMANDS_PLAYER                       = "nwncogs.from.bot.commands.player";
const string NWNCOGS_CHANNEL_OUTGOING_RESPONSE_PLAYER                       = "nwncogs.from.nwserver.response.player";

const string NWNCOGS_CHANNEL_INCOMING_COMMANDS_ADMIN                        = "nwncogs.from.bot.commands.admin";
const string NWNCOGS_CHANNEL_OUTGOING_RESPONSE_ADMIN                        = "nwncogs.from.nwserver.response.admin";

const string NWNCOGS_CHANNEL_INCOMING_CHAT                                  = "nwncogs.from.bot.chat";
const string NWNCOGS_CHANNEL_OUTGOING_CHAT                                  = "nwncogs.from.nwserver.chat";

/* *** */

// Empty parameters will not be shown
struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Simple(
    string sAuthor = "",
    string sTitle = "",
    string sDescription = "",
    int nColor = -1
);
// Empty parameters will not be shown
struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Full(
    string sAuthor = "",
    string sAuthorIconUrl = "",
    string sTitle = "",
    string sDescription = "",
    int nColor = -1,
    string sImageUrl = "",
    string sThumbnailUrl = "",
    string sFooterText = "",
    string sFooterIconUrl = ""
);

// Send a simple text only response to Discord
void NWNCogs_PublishDiscordResponse_Simple(
    string sOutgoingChannel,
    string sResponse
);
// Send an embed response to Discord
void NWNCogs_PublishDiscordResponse_Embed(
    string sOutgoingChannel,
    struct NWNCogs_DiscordEmbed discordEmbed
);
// Helper function to build the actual json response from a discord embed struct
string NWNCogs_JsonResponseBuilder(
    struct NWNCogs_DiscordEmbed discordEmbed
);
// Convert a RBG color to a Discord Color
// Parameter range: 0-255
int NWNCogs_RBGToDiscordColor(
    int nRed = 0,
    int nGreen = 0,
    int nBlue = 0
);
// Wrapper function
int NWNCogs_GetIsValidBotCommand(
    string sChannel,
    struct NWNX_Redis_PubSubMessageData data
);

/* *** */

struct NWNCogs_DiscordEmbed
{
    string sTitle;
    string sDescription;
    int nColor;

    string sImageUrl;
    string sThumbnailUrl;

    string sAuthor;
    string sAuthorIconUrl;

    string sFooterText;
    string sFooterIconUrl;
};

struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Empty()
{
    struct NWNCogs_DiscordEmbed discordEmbed;

    discordEmbed.sTitle = "";
    discordEmbed.sDescription = "";
    discordEmbed.nColor = 0;

    discordEmbed.sImageUrl = "";
    discordEmbed.sThumbnailUrl = "";

    discordEmbed.sAuthor = "";
    discordEmbed.sAuthorIconUrl = "";

    discordEmbed.sFooterText = "";
    discordEmbed.sFooterIconUrl = "";

    return discordEmbed;
}

struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Simple(
    string sAuthor = "",
    string sTitle = "",
    string sDescription = "",
    int nColor = -1
)
{
    struct NWNCogs_DiscordEmbed discordEmbed = NWNCogs_DiscordEmbed_Empty();

    if (GetStringLength(sTitle) > 0)
    {
        discordEmbed.sTitle = sTitle;
    }
    if (GetStringLength(sDescription) > 0)
    {
        discordEmbed.sDescription = sDescription;
    }
    if (nColor > -1)
    {
        discordEmbed.nColor = nColor;
    }
    if (GetStringLength(sAuthor) > 0)
    {
        discordEmbed.sAuthor = sAuthor;
    }
    return discordEmbed;
}

struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Full(
    string sAuthor = "",
    string sAuthorIconUrl = "",
    string sTitle = "",
    string sDescription = "",
    int nColor = -1,
    string sImageUrl = "",
    string sThumbnailUrl = "",
    string sFooterText = "",
    string sFooterIconUrl = ""
)
{
    struct NWNCogs_DiscordEmbed discordEmbed = NWNCogs_DiscordEmbed_Empty();

    if (GetStringLength(sTitle) > 0)
    {
        discordEmbed.sTitle = sTitle;
    }
    if (GetStringLength(sDescription) > 0)
    {
        discordEmbed.sDescription = sDescription;
    }
    if (nColor > -1)
    {
        discordEmbed.nColor = nColor;
    }
    if (GetStringLength(sImageUrl) > 0)
    {
        discordEmbed.sImageUrl = sImageUrl;
    }
    if (GetStringLength(sThumbnailUrl) > 0)
    {
        discordEmbed.sThumbnailUrl = sThumbnailUrl;
    }
    if (GetStringLength(sAuthor) > 0) {
        discordEmbed.sAuthor = sAuthor;
    }
    if (GetStringLength(sAuthorIconUrl) > 0)
    {
        discordEmbed.sAuthorIconUrl = sAuthorIconUrl;
    }
    if (GetStringLength(sFooterText) > 0) {
        discordEmbed.sFooterText = sFooterText;
    }
    if (GetStringLength(sFooterIconUrl) > 0) {
        discordEmbed.sFooterIconUrl = sFooterIconUrl;
    }
    return discordEmbed;
}

/* *** */

void NWNCogs_PublishDiscordResponse_Simple(
    string sOutgoingChannel,
    string sResponse
)
{
    NWNX_Redis_PUBLISH(sOutgoingChannel, sResponse);
}

void NWNCogs_PublishDiscordResponse_Embed(
    string sOutgoingChannel,
    struct NWNCogs_DiscordEmbed discordEmbed
)
{
    string sEmbed = NWNCogs_JsonResponseBuilder(discordEmbed);

    NWNX_Redis_PUBLISH(sOutgoingChannel, sEmbed);
}

/* *** */

string NWNCogs_JsonResponseBuilder(
    struct NWNCogs_DiscordEmbed discordEmbed
)
{
    string sEmbed = "";

    sEmbed += "{";

    sEmbed += "\"title\": \""           + discordEmbed.sTitle               + "\",";
    sEmbed += "\"description\": \""     + discordEmbed.sDescription         + "\",";
    sEmbed += "\"color\": "             + IntToString(discordEmbed.nColor)  + ",";

    sEmbed += "\"image_url\": \""       + discordEmbed.sImageUrl            + "\",";
    sEmbed += "\"thumbnail_url\": \""   + discordEmbed.sThumbnailUrl        + "\",";

    sEmbed += "\"author\": \""          + discordEmbed.sAuthor              + "\",";
    sEmbed += "\"author_icon_url\": \"" + discordEmbed.sAuthorIconUrl       + "\",";

    sEmbed += "\"footer_text\": \""     + discordEmbed.sFooterText          + "\",";
    sEmbed += "\"footer_icon_url\": \"" + discordEmbed.sFooterIconUrl       + "\"";

    sEmbed += "}";

    return sEmbed;
}

int NWNCogs_RBGToDiscordColor(
    int nRed = 0,
    int nGreen = 0,
    int nBlue = 0
)
{
    if( nRed < 0 ) nRed = 0; else if( nRed > 255 ) nRed = 255;
    if( nGreen < 0 ) nGreen = 0; else if( nGreen > 255 ) nGreen = 255;
    if( nBlue < 0 ) nBlue = 0; else if( nBlue > 255 ) nBlue = 255;

    int nColor = (nRed * 65536) + (nGreen * 256) + nBlue;

    return nColor < 1 ? 1 : nColor;
}

int NWNCogs_GetIsValidBotCommand(
    string sChannel,
    struct NWNX_Redis_PubSubMessageData data
)
{
    return data.channel == sChannel && GetStringLength(data.message) > 0;
}

/* *** */
