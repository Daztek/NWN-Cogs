import discord
import asyncio
import json
from aredis import StrictRedis
from discord.ext import commands


class NWN:
    """A Discord <-> Redis <-> NWServer Communication Cog"""

    def __init__(self, bot):
        self.bot = bot
        
        self.redisConn = StrictRedis(host='127.0.0.1', port=6379, db=0)
        
        self.redisSubscribe = self.redisConn.pubsub()
        self.redisSubFuture = asyncio.ensure_future(self.sub_reader(self.redisSubscribe))

    @commands.command()
    async def nwn(self, redis_command: str):
        """Publishes a Command to the Redis Server"""
        await self.redisConn.publish('from.bot', redis_command)

        await self.bot.say("To NWServer: {}".format(redis_command))
   
    async def sub_reader(self, redisSubscribe):
        await redisSubscribe.subscribe('from.nwserver')

        while self == self.bot.get_cog('NWN') and True:
            message = await redisSubscribe.get_message(ignore_subscribe_messages=True)            

            if message:
                data = json.loads(message["data"])

                embed = discord.Embed(title=data["title"], description=data["description"], color=data["color"])
                embed.set_author(name=data["author"], icon_url=data["author_icon_url"])
                embed.set_thumbnail(url=data["thumbnail_url"])
                embed.set_footer(text=data["footer_text"], icon_url=data["footer_icon_url"])
        
                await self.bot.send_message(self.bot.get_channel('522000965746819073'), embed=embed)

            await asyncio.sleep(0.001)
            #await self.bot.send_message(self.bot.get_channel('522000965746819073'), "From NWServer: {}".format(msg["data"]))  
        
    def __unload(self):
        self.redisSubscribe.close()
        self.redisSubFuture.cancel()

def setup(bot):  
    n = NWN(bot)
    bot.add_cog(n)