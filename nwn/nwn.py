import discord
import asyncio
import json
import os
from discord.ext import commands
from cogs.utils import checks
from cogs.utils.dataIO import fileIO

try:
    import aredis
    from aredis import StrictRedis
except Exception as e:
    raise RuntimeError("You must run `pip3 install aredis` to use this cog") \
        from e

class NWN:
    """A Discord <-> Redis <-> NWServer Communication Cog"""

    def __init__(self, bot):
        self.bot = bot

        self.settings = fileIO('data/nwn/settings.json', 'load')
        self.valid_settings = self.check_settings()
        if not self.valid_settings:
            raise RuntimeError("Error: Missing settings")

        self.responseChannel = self.bot.get_channel(self.settings["discord_response_channel_id"])
        self.chatChannel = self.bot.get_channel(self.settings["discord_chat_channel_id"])

        self.redisConn = StrictRedis(host=self.settings["redis_host"], port=self.settings["redis_port"])        
        self.redisSubscribe = self.redisConn.pubsub()
        self.redisSubFuture = asyncio.ensure_future(self.sub_reader(self.redisSubscribe))

    def check_settings(self):
        for k, v in self.settings.items():
            if v == '' or v == 0:
                print("Error: You need to set your {} in ".format(k) +
                      "data/nwn/settings.json")
                return False
        return True

    @commands.command(no_pm=True)
    async def publish(self, *, redis_command: str):
        """Publishes a Command to the Redis Server"""

        await self.redisConn.publish('nwncogs.from.bot.commands', redis_command)

        await self.bot.say("To NWServer: {}".format(redis_command))

    @commands.command(no_pm=True)
    @checks.admin()
    async def publish_r(self, *, redis_command: str):
        """Publishes a Restricted Command to the Redis Server"""

        await self.redisConn.publish('nwncogs.from.bot.commands.restricted', redis_command)

        await self.bot.say("(Restricted) To NWServer: {}".format(redis_command))        
   
    async def sub_reader(self, redisSubscribe):
        await redisSubscribe.subscribe('nwncogs.from.nwserver.response', 'nwncogs.from.nwserver.chat')

        while self == self.bot.get_cog('NWN'):
            message = await redisSubscribe.get_message(ignore_subscribe_messages=True)            

            if message:
                channel = message["channel"].decode('UTF-8')

                if channel == "nwncogs.from.nwserver.response":
                    messageChannel = self.responseChannel 
                elif channel == "nwncogs.from.nwserver.chat":
                    messageChannel = self.chatChannel

                try:
                    data = json.loads(message["data"])
                except ValueError:
                    await self.bot.send_message(messageChannel, "From NWServer: {}".format(message["data"].decode('UTF-8')))
                else:
                    embed = discord.Embed(title=data["title"], description=data["description"], color=data["color"])
                    embed.set_image(url=data["image_url"])
                    embed.set_author(name=data["author"], icon_url=data["author_icon_url"])
                    embed.set_thumbnail(url=data["thumbnail_url"])
                    embed.set_footer(text=data["footer_text"], icon_url=data["footer_icon_url"])
            
                    await self.bot.send_message(messageChannel, embed=embed)

            await asyncio.sleep(0.001)

    async def check_chat_messages(self, message):
        if message.author.id == self.bot.user.id:
            return

        if message.channel == self.chatChannel:
            await self.redisConn.publish('nwncogs.from.bot.chat', "{}: {}".format(message.author, message.content))
        
    def __unload(self):
        self.redisSubscribe.close()
        self.redisSubFuture.cancel()
        self.bot.remove_listener(self.check_chat_messages, "on_message")

def check_folder():
    if not os.path.exists("data/nwn"):
        print("Creating data/nwn folder...")
        os.makedirs("data/nwn")

def check_file():
    settings = {"redis_host": "",
                "redis_port": 0,
                "discord_response_channel_id": "",
                "discord_chat_channel_id": ""}

    f = "data/nwn/settings.json"
    
    if not fileIO(f, "check"):
        print("Creating default NWN settings.json...")
        fileIO(f, "save", settings)

def setup(bot):
    check_folder()
    check_file()
      
    n = NWN(bot)
    bot.add_listener(n.check_chat_messages, "on_message")
    bot.add_cog(n)