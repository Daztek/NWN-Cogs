import discord
import aioredis
import asyncio
from discord.ext import commands
from itertools import count

class NWNPublish:
    """My custom cog that does stuff!"""

    def __init__(self, bot):
        self.bot = bot

    @commands.command()
    async def nwnpublish(self):
        """This does stuff!"""

        #Your code will go here
        await self.bot.say("Publishing...!")

    async def reader(ch):
        async for msg in ch.iter(encoding='utf-8'):
            await self.bot.say("Message: " + msg)

def setup(bot):
    sub = await aioredis.create_redis('redis://localhost')

    channel = await sub.subscribe('test')

    tsk = asyncio.ensure_future(reader(channel))

    bot.add_cog(NWNPublish(bot))