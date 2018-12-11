import discord
import aioredis
import asyncio
from discord.ext import commands
from itertools import count

class NWN:
    """My custom cog that does stuff!"""

    def __init__(self, bot):
        self.bot = bot    

    @commands.command()
    async def ping(self):
        """This does stuff!"""
        pub = await aioredis.create_redis(('localhost', 6379))

        await pub.publish('from.bot', 'PING')

        pub.close()

        await self.bot.say("To NWServer: PING")
   
    async def reader(self):
        sub = await aioredis.create_redis(('localhost', 6379))
        res = await sub.subscribe('from.nwserver')
        ch = res[0]

        while (await ch.wait_message()):
            msg = await ch.get(encoding='UTF-8')
            await self.bot.send_message(self.bot.get_channel('522000965746819073'), "From NWServer: {}".format(msg))

def setup(bot):
    n = NWN(bot)

    loop = asyncio.get_event_loop()
    loop.create_task(n.reader())

    bot.add_cog(n)