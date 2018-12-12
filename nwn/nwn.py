import discord
import aioredis
import asyncio
from discord.ext import commands

class NWN:
    """A Discord <-> Redis <-> NWServer Communication Cog"""

    def __init__(self, bot):
        self.bot = bot

        loop = asyncio.get_event_loop()
        self.task = loop.create_task(self.sub_reader())   

    @commands.command()
    async def nwn(self, redis_command: str):
        """Publishes a Command to the Redis Server"""
        pub = await aioredis.create_redis(('localhost', 6379))

        await pub.publish('from.bot', redis_command)

        pub.close()

        await self.bot.say("To NWServer: {}".format(redis_command))
   
    async def sub_reader(self):
        sub = await aioredis.create_redis(('localhost', 6379))
        res = await sub.subscribe('from.nwserver')
        ch = res[0]

        while await ch.wait_message():
            msg = await ch.get(encoding='UTF-8')
            
            embed=discord.Embed(title="Server Response", description=msg, color=0x00ff00)
            embed.set_author(name="Server Name")
            embed.set_thumbnail(url="https://i.imgur.com/k7AyXCD.png")
            
            await self.bot.send_message(self.bot.get_channel('522000965746819073'), embed=embed)
            
            #await self.bot.send_message(self.bot.get_channel('522000965746819073'), "From NWServer: {}".format(msg))

    def __unload(self):
        self.task.cancel()

def setup(bot):  
    n = NWN(bot)
    bot.add_cog(n)