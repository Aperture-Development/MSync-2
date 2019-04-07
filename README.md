# MSync-2

![BuildStatus](https://tcci.aperture-development.de/app/rest/builds/buildType:(id:MSync2_Publish)/statusIcon.svg)
[![Issues](https://img.shields.io/github/issues-raw/Aperture-Development/MSync-2.svg)](https://github.com/Aperture-Development/MSync-2/issues)
[![Chat](https://img.shields.io/discord/272563407209889792.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/JpDPa6w)
![Size](https://img.shields.io/github/repo-size/Aperture-Development/MSync-2.svg)
[![Licence](https://img.shields.io/badge/license-by--nc--sa--4.0-green.svg)](https://github.com/Aperture-Development/MSync-2/blob/master/LICENSE)
[![Release](https://img.shields.io/github/release/Aperture-Development/MSync-2.svg)](https://github.com/Aperture-Development/MSync-2/releases)

What is MSync-2 ?

MSync is a all around GMod server synchronisation addon. The addon is and will always be free to use. 

MSync 2 is a new version of https://github.com/Aperture-Development/MSync

It requires [MySQLoo](https://github.com/FredyH/MySQLOO) to work.

++**Why version 2?**++

Let's be honest here, version one is a broken piece of shit. It errors out everywhere, the GUI does not work and when you remove it, all bans and stuff are lost, because we overwrite the origiinal commands.

It was my first addon I ever made, and now looking back with my new knowledge, I feel ashamed for the code.

Version 2 will include a lot of changes, like:
- New Database Structure
- Completly own GUI System (Means we use GMod ressources and not XGUI anymore, because XGUI is shit)
- Module system, to easily extend features
- STEAK


# A Note to the different versions

MSync 2 is Split up in 3 versions:
- EGG
- CHEESE
- STEAK

**EGG** is the WIP addon which does not work yet at all. DO NOT USE ANYTHING OF THIS! The file structure will change propably. If you have problems with a EGG version, we do not Provide support. Use the STEAK version or at least CHEESE.

**CHEESE** is the beta phase of the addon. The addon works, but has propably bugs everywhere that needs to be found yet. If you have errors whith this version, please inform us with a GitHub issue or over our ticketsystem: [https://www.Aperture-Development.de/ticketsystem](https://www.Aperture-Development.de/ticketsystem)

**STEAK** is the stable version of MSync 2. This version is safe to be used on your server.

++**Why do all versions are named after food?**++

Because it's a joke, as you maybe know, Debian distributions are named after the characters of Toy Story, and I thought its funny to have something like that for our Addons.

# A note to modules

If you plan on extending the features of MSync 2, please copy and use the samplemodule files. You can distribute the Module under every licence you like. We always use the root_dir/LICENCE which is basicly the Licence you get the addon with. If you download it from GitHub or Steam it will most likely be under the by-nc-sa 4.0 licence, while when you download it over our website, you will get the Aperture Development Commercial licence.

# Installation

You need to install some things manually on the Server in order for MSync to work. 

First you need libmysql on windows or libmysqlclient on linux. You can find them here:
Windows: https://github.com/FredyH/MySQLOO/raw/master/MySQL/lib/windows/libmysql.dll
Linux: https://github.com/FredyH/MySQLOO/raw/master/MySQL/lib/linux/libmysqlclient.so.18
Put the file in the same folder where your scrds.exe or your scrds_linux file is.

Then you need MySQLoo 9 or higher. You can download MySQLoo from here:
https://github.com/FredyH/MySQLOO/releases
Select win32 if your server runs on windows, otherwise use the linux dll.
Put the dll file in your lua/bin folder. If you don't have one, create it.
it should look like this:

```
bin
garrysmod
->lua
-->bin
--->gmsv_mysql_<version>.dll
```

After that just install the addon by putting it in your servers workshop collection or download the zip file from github and put the folder in your servers addon folder: 
https://github.com/Aperture-Development/MSync-2/archive/master.zip

When the server is started, everything should be ready for MSync 2. You can access the admin gui using "!msync"

# Features

++**Server Groups:**++

>Server groups allow you to group your servers in sub teams. Modules will just sync things that are explicity told to sync it across all servers, otherwise it will just sync it with servers that have the same server group.


++**MRSync:**++

>**M**ySQL **R**ank **Sync**hronisation
>
>MRSync allows you to synchronise your staff team across your servers without the need to add/remove a staff member on every server. Just add a user to a rank and he will also have the rank on all other servers. For now it is important that the ranks you synchronise also exist on all servers.
>
>You want some ranks to not be synced?
There is a rank blacklist for ranks that dont get saved to the database. Just add the rank and you are good to go.
>
>You want some ranks to be synced across all servers and some just for ( as example ) your DarkRP servers?
The server_group option allows you to do just that. Just sub-categorise your servers and your ranks now just get synced within this group. You can exclude ranks from that rule and force them to synchronise across all servers using the allserver table, all ranks in that table get saved as ranks for the whole network.


++**MBSync:**++

>**M**ySQL **B**an **Sync**hronisation
>
>MBSync allos you to synchronise your bans across all servers ( network bans ). This Module is also server_group bound, means when you ban a user on a server in the group darkrp they dont get banned on servers with a different group.
>
>Commands:
>
>!mban - Opens ban GUI 
>
>!mban [Name] [Length] [global] [Reason] - bans a player
>
>!mbanid [SteamID/SteamID64] [Length] [global] [Reason] - bans a players steamid
>
>!munban [SteamID/SteamID64] - unbans a player
>
>!mbsync - Opens Ban list


++**Planned Features**++

>- UTime synchronisation - Codename: MUSync
>- MySQL Warning system - Codename: MWS
>- Permission synchronisation - Codename: MPSync
>- MSync synchronisation - Codename: MSSync



# Other info

MSync 2 - GitHub is distributed under the by-nc-sa 4.0 Int licence. Please read the LICENCE file in the root directory of MSync 2.

Support is provided over our ticketsystem:
[https://www.Aperture-Development.de/ticketsystem](https://www.Aperture-Development.de/ticketsystem)