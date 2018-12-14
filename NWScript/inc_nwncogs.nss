#include "nwnx_redis"
#include "nwnx_redis_ps"

/*
    NWNCogs Functions
    Repository: https://github.com/Daztek/NWN-Cogs
*/

const string NWNCOGS_INCOMING_REDIS_CHANNEL                     = "nwncogs.from.bot.commands";
const string NWNCOGS_INCOMING_REDIS_CHANNEL_RESTRICTED          = "nwncogs.from.bot.commands.restricted";
const string NWNCOGS_INCOMING_REDIS_CHANNEL_CHAT                = "nwncogs.from.bot.chat";
const string NWNCOGS_OUTGOING_REDIS_CHANNEL                     = "nwncogs.from.nwserver.response";
const string NWNCOGS_OUTGOING_REDIS_CHANNEL_CHAT                = "nwncogs.from.nwserver.chat";

/* *** */

struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Simple(string sAuthor, string sTitle, string sDescription, int nColor);
struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Full(string sAuthor, string sAuthorIconUrl, string sTitle, string sDescription, int nColor, string sImageUrl, string sThumbnailUrl, string sFooterText, string sFooterIconUrl);

// Send a simple text only response to Discord
void NWNCogs_PublishDiscordResponse_Simple(string sChannel, string sResponse);
// Send an embed response to Discord
void NWNCogs_PublishDiscordResponse_Embed(string sChannel, struct NWNCogs_DiscordEmbed de);

// Convert a RBG color to a Discord Color
// Parameter range: 0-255
int NWNCogs_RBGToDiscordColor(int nRed, int nGreen, int nBlue);

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

struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Simple(string sAuthor, string sTitle, string sDescription, int nColor)
{
    struct NWNCogs_DiscordEmbed discordEmbed = NWNCogs_DiscordEmbed_Empty();

    discordEmbed.sTitle = sTitle;
    discordEmbed.sDescription = sDescription;
    discordEmbed.nColor = nColor;
    discordEmbed.sAuthor = sAuthor;

    return discordEmbed;
}

struct NWNCogs_DiscordEmbed NWNCogs_DiscordEmbed_Full(string sAuthor, string sAuthorIconUrl, string sTitle, string sDescription, int nColor, string sImageUrl, string sThumbnailUrl, string sFooterText, string sFooterIconUrl)
{
    struct NWNCogs_DiscordEmbed discordEmbed = NWNCogs_DiscordEmbed_Empty();

    discordEmbed.sTitle = sTitle;
    discordEmbed.sDescription = sDescription;
    discordEmbed.nColor = nColor;
    discordEmbed.sImageUrl = sImageUrl;
    discordEmbed.sThumbnailUrl = sThumbnailUrl;
    discordEmbed.sAuthor = sAuthor;
    discordEmbed.sAuthorIconUrl = sAuthorIconUrl;
    discordEmbed.sFooterText = sFooterText;
    discordEmbed.sFooterIconUrl = sFooterIconUrl;

    return discordEmbed;
}

/* *** */

void NWNCogs_PublishDiscordResponse_Simple(string sChannel, string sResponse)
{
    NWNX_Redis_PUBLISH(sChannel, sResponse);
}

void NWNCogs_PublishDiscordResponse_Embed(string sChannel, struct NWNCogs_DiscordEmbed discordEmbed)
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

    NWNX_Redis_PUBLISH(sChannel, sEmbed);
}

int NWNCogs_RBGToDiscordColor(int nRed, int nGreen, int nBlue)
{
    if( nRed < 0 ) nRed = 0; else if( nRed > 255 ) nRed = 255;
    if( nGreen < 0 ) nGreen = 0; else if( nGreen > 255 ) nGreen = 255;
    if( nBlue < 0 ) nBlue = 0; else if( nBlue > 255 ) nBlue = 255;

    int nColor = (nRed * 65536) + (nGreen * 256) + nBlue;

    return nColor < 1 ? 1 : nColor;
}