import discord
from discord.ext import commands

class NWNPublish:
    """My custom cog that does stuff!"""

    def __init__(self, bot):
        self.bot = bot

    @commands.command()
    async def nwnpublish(self):
        """This does stuff!"""

        #Your code will go here
        await self.bot.say("Publishing...")

def setup(bot):
    bot.add_cog(NWNPublish(bot))