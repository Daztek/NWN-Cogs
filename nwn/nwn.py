import discord
import asyncio
import json
import os
from discord.ext import commands
from cogs.utils import checks
from cogs.utils.dataIO import fileIO

try:
    import aredis
except Exception as e:
    raise RuntimeError("You must run `pip3 install aredis` to use this cog") \
        from e

class NWN:
    """A Discord <-> Redis <-> NWServer Communication Cog"""

    def __init__(self, bot):
        self.bot = bot

        self.settings = fileIO('data/nwn/settings.json', 'load')

        if (
            self.settings["DISCORD_CHAT_CHANNEL_ID"] is None or
            self.settings["DISCORD_CHAT_CHANNEL_ID"] == ""
        ):
            print("NWN -> NOTICE: Chat Channel ID not set, disabling chat functionality!")
        else:
            self.bot.add_listener(self.check_chat_messages, "on_message")

        self.redisConn = aredis.StrictRedis(host=self.settings["REDIS_HOSTNAME"], port=self.settings["REDIS_PORT"])        
        self.redisSubscribe = self.redisConn.pubsub()
        self.redisSubFuture = asyncio.ensure_future(self.sub_reader(self.redisSubscribe))

    @commands.command(no_pm=True)
    async def player(self, *, redis_command: str):
        """Publishes a Command to the Redis Server"""

        await self.redisConn.publish('nwncogs.from.bot.commands.player', redis_command)

        #await self.bot.say("Player Command To NWServer: {}".format(redis_command))

    @commands.command(no_pm=True)
    @checks.admin()
    async def admin(self, *, redis_command: str):
        """Publishes an Admin Command to the Redis Server"""

        await self.redisConn.publish('nwncogs.from.bot.commands.admin', redis_command)

        #await self.bot.say("Admin Command To NWServer: {}".format(redis_command))        
   
    async def sub_reader(self, redisSubscribe):
        await redisSubscribe.subscribe(
            'nwncogs.from.nwserver.response.player',
            'nwncogs.from.nwserver.response.admin',
            'nwncogs.from.nwserver.chat',
            'nwncogs.from.nwserver.broadcast'
        )

        while self == self.bot.get_cog('NWN'):
            message = await redisSubscribe.get_message(ignore_subscribe_messages=True)            

            if message:
                redisChannelStr = message["channel"].decode('UTF-8')

                if redisChannelStr == "nwncogs.from.nwserver.response.player":
                    discordChannelStr = self.settings["DISCORD_PLAYER_CHANNEL_ID"]
                elif redisChannelStr == 'nwncogs.from.nwserver.response.admin':
                    discordChannelStr = self.settings["DISCORD_ADMIN_CHANNEL_ID"]
                elif redisChannelStr == "nwncogs.from.nwserver.chat":
                    discordChannelStr = self.settings["DISCORD_CHAT_CHANNEL_ID"]
                elif redisChannelStr == "nwncogs.from.nwserver.broadcast":
                    discordChannelStr = self.settings["DISCORD_BROADCAST_CHANNEL_ID"]
                else:
                    discordChannelStr = None

                if (
                    discordChannelStr is None or
                    discordChannelStr == ""
                ):
                    print("NWN -> NOTICE: Message received from '{}' but Response Channel ID has not been set!".format(redisChannelStr))

                discordChannel = self.bot.get_channel(discordChannelStr)

                if discordChannel is None:
                    print("NWN -> NOTICE: Message received from '{}' but unable to send to discord channel '{}'; possibly we're not connected.".format(redisChannelStr, discordChannelStr))
                else:
                    try:
                        data = json.loads(message["data"])
                        embed = discord.Embed(title=data["title"], description=data["description"], color=data["color"])
                        embed.set_image(url=data["image_url"])
                        embed.set_author(name=data["author"], icon_url=data["author_icon_url"])
                        embed.set_thumbnail(url=data["thumbnail_url"])
                        embed.set_footer(text=data["footer_text"], icon_url=data["footer_icon_url"])
                        if len(data["fields_inline"]) > 0:
                            if len(data["fields_name"]) > 0:
                                embed.add_field(
                                    name=data["fields_name"],
                                    value=data["fields_value"],
                                    inline=data["fields_inline"] in ('True', 'true', 'TRUE')
                                )
                            else:
                                print("NWN -> NOTICE: Message received from '{}' had non-empty 'fields_value' key but empty 'fields_name' key;  This would cause a BAD REQUEST. Skipping message".format(redisChannelStr))
                        await self.bot.send_message(discordChannel, embed=embed)
                    # json.loads() will throw a ValueError
                    # exception if the data is not json-formatted
                    except ValueError as e:
                        # The data is not json;  Just send it
                        await self.bot.send_message(discordChannel, "{}".format(message["data"].decode('UTF-8')))

            await asyncio.sleep(0.001)

    async def check_chat_messages(self, message):
        if message.author.id == self.bot.user.id:
            return

        if message.channel == self.chatChannel:
            await self.redisConn.publish('nwncogs.from.bot.chat', "{}~{}".format(message.author.display_name, message.content))
        
    def __unload(self):
        self.redisSubscribe.close()
        self.redisSubFuture.cancel()
        
        if self.chatChannel:
            self.bot.remove_listener(self.check_chat_messages, "on_message")

def check_folder():
    if not os.path.exists("data/nwn"):
        print("Creating data/nwn folder...")
        os.makedirs("data/nwn")

def check_file():
    settings = {"REDIS_HOSTNAME": "localhost",
                "REDIS_PORT": 6379,
                "DISCORD_PLAYER_CHANNEL_ID": "",
                "DISCORD_ADMIN_CHANNEL_ID": "",
                "DISCORD_CHAT_CHANNEL_ID": "",
                "DISCORD_BROADCAST_CHANNEL_ID": ""}

    f = "data/nwn/settings.json"
    
    if not fileIO(f, "check"):
        print("Creating default NWN settings.json...")
        fileIO(f, "save", settings)

def setup(bot):
    check_folder()
    check_file()
      
    n = NWN(bot)
    bot.add_cog(n)
