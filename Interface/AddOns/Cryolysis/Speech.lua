------------------------------------------------------------------------------------------------------
-- Cryolysis
--
-- Based on Necrosis LdC by Lomig and Nyx (http://necrosis.larmes-cenarius.net)
-- Original Necrosis Idea : Infernal (http://www.revolvus.com/games/interface/necrosis/)
-- Cryolysis Maintainer : Kaeldra of Aegwynn
--
-- Contact : darklyte@gmail.com
-- Send me in-game mail!  Yersinia on Aegwynn, Horde side.
-- Guild: <Working as Intended>
-- Version Date: 07.14.2006
------------------------------------------------------------------------------------------------------



-- Text for speeches by the mage
--------------------------------------
-- Here are some random speeches for your mage.  You can add more to fit your
-- magey-way-of-thinking a little more!
-- Need some help ? :)
-- Correct syntax is "Blah blah blah" SelectedPlayer "Blah blah blah"
-- If you want to write "In few seconds 'Player's name' will be able to help us"
-- The target's name is replaced by <target>, but CASE SENSITIVE!
-- you need to add before the } :
-- "In few seconds <target> will be able to help us",
-- 
-- The same thing is available for all messages.  If you need any help at all, 
-- Don't hesitate to e-mail me at darklyte@gmail.com :)


-------------------------------------
--  ENGLISH VERSION --
-------------------------------------

function Cryolysis_Localization_Speech_En()

	CRYOLYSIS_TELEPORT_MESSAGE = {
		[1] = "I'm heading straight to <portal>! You can't stop the signal!",
		[2] = "Err...something's come up. I've got to be in <portal> like, NOW for another freaking meeting. Stupid 'Mage Meeting' and all that crap.",
		[3] = "Oh look! What's over there! *VANISH* Where'd I go? Buah hahaha. Actually, just look in <portal>, I'll probably be at the repair shop.",
		[4] = "Woohoo! I'm solo flying the <portal> express! Don't you wish you had three free hearthstones?",
		[5] = "PS, since I can 'port to <portal>, my hearth is set in Gadget :P",
		[6] = "Please don't enter my airspace. I'll be leaving for <portal> in about ten seconds.",
		[7] = "I hope I got the spell right this time! Last time, I was trying for <portal> but ended up scattered all over Azeroth!",
		[8] = "10 silver to get to <portal>?!  Well, it's better than waiting an hour",
		[9] = "I can think of two places I'd rather be than here.  Sadly, the most convenient one is <portal>",
	};
	CRYOLYSIS_PORTAL_MESSAGE = {
		[1] = "Step right up! Fly the friendly skies of <player>'s Air Service, now departing for <portal>.",
		[2] = "No promises that you'll actually get to <portal> by clicking this. Seriously.",
		[3] = "Chortle chortle, it's a portal!",
		[4] = "<player>'s Air service is proud to be servicing your one-way trip to <portal>. Please remember to close your eyes for the duration because it can be scary as hell.",
		[5] = "DISCLAIMER: I RECEIVED MY PORTAL LICENSE OFF THE AH. CLICK AT YOUR OWN RISK.",
		[6] = "Well, you cooouulllddd click this portal to <portal>, but are you sure you really want to go there? I mean, seriously, <portal>? WTF is wrong with you. Do you know who LIVES there?",
		[7] = "Tired of letting your arms get tired on your long trip back to <portal>? Just click here then, you lazy non-hearthing bums",
		[8] = "Entering through this dimensional gateway will get you to <portal>",
		[9] = "Okay, <player>, focus.  They want to go to <portal>, not the middle of the Maelstrom.  I can do this.. <portal>, not ocean.",
		[10] = "Why go to <portal> when we can bring <portal> here?  Please click the portal to help me summon the city!",
		[11] = "Now opening a portal to Ironforge.  Or was it Orgrimmar? Maybe Stormwind or Thunder bluff? I guess we'll just have to find out!",
		[12] = "Whatever you do, DON'T TOUCH THE PORTAL",
		[13] = "Gateway to hell? Coming right up!",
	};
	CRYOLYSIS_POLY_MESSAGE = {
		["Sheep"] = {
			[1] = "<target> has been baaaaaaaaad!",
			[2] = "I'm little bopeep! Don't touch the sheep!",
			[3] = "Sheeping <target>, break it and I break your kneecaps.",
			[4] = "Skies above and oceans deep, <target> is now a sheep!",
			[5] = "Sheeping <target>, DON'T TOUCH MY MUTTON!",
			[6] = "Sheeping <target>! Drop what you're doing and break it! ",
			[7] = "Stay away from <target>, I still need mats for [Wool Socks]",
			[8] = "Okay <target>, repeat after me. Baaaaa",
			[9] = "Sheeping <target>. Everytime you break a sheep, God kills a kitten.",
			[10] = "Polymorphing <target>!  You break it, you tank it.",
			[11] = "<target> is my sheep. There are many others like it but this one is mine.",
			[12] = "Polymorphing <target>, please keep your pants up.",
			[13] = "Baa, Baa, <target>.  Have you any wool?",
			[14] = "Polymorphing <target> because sheep don't say no.",
			[15] = "Polymorph on <target>. Repeated poking may cause explosions",
			[16] = "What's white and fluffy and covered in wool?  <target> of course!",
			[17] = "<target>, have you ever read the works of Franz Kafka?",
			[18] = "How's my sheeping? Call 1-800-BAH-RAM-U",
			[19] = "Bah, <target>",
			[20] = "Polymorph on <target>.  You break it, you buy it.",
			[21] = "Polymorph on *yawn* <target>.  So many sheep... zzzz",
			[22] = "Go deep into your cave, <target>, and find your power animal",
			[23] = "I know how frightening and intimidating mutton can be, but please try to overcome this phobia you have of <target>",
			
		},
		["Pig"] = {
			[1] = "Sooooo Weeeeee! here Piggy <target>. Dont Steal the Bacon!",
			[2] = "Porking <target>.  Oink! Oink!",
			[3] = "PORKCHOP SANDWICHES!!",
			[4] = "I smell bacon I smell pork, look out <target> I have a fork!",
			[5] = "<target>:  The other white meat.",
			[6] = "That'll do, <target>.  That'll do.",
			[7] = "In space, no one can hear you squeal",
			[8] = "<target>, will you be Mr. Wiggles' friend?",
			[9] = "I think <target> was raised in a barn",
			[10] = "<target>'s new name shall be Comrade Napoleon",
			[11] = "Orsen Wells wants to have a word with you, <target>",
            [12] = "<target> is not kosher!",
            [13] = "Congrats, <target>, you are now the Prince of Denmark!",
            [14] = "This above all: to thine own self be true, And it must follow, as the night the day, Thou canst not then be false to any man.",
            [15] = "Dog's can't tell that <target>'s not bacon.",
            [16] = "<target> makes me want to read Hamlet.",
            
		},
		["Turtle"] = {
			[1] = "GO SQUIRTLE!",
			[2] = "Slow and steady won't win the race for <target> this time",
			[3] = "Hey <target>, you up for some soup? =D",
			[4] = "GAM-E-RA! GAM-E-RA! <target> is a friend to children everywhere.",
			[5] = "<target> is a hero on the half-shell!",
		},
	};
	CRYOLYSIS_STEED_MESSAGE = {
		[1] = "If it wasn't for my <mount>, I wouldn't have spent that year in college.",
		[2] = "The directions said to just add water and... WHOA a <mount>!",
		[3] = "My <mount> ate all my conjured food again!  Better make more...",
	};
	CRYOLYSIS_FREEZE_MESSAGE = {
		[1] = "I enjoy my <target>s on the rocks",
		[2] = "Looks like <target> needs to get a sweater!",
		[3] = "<3 Freezing Band",
		[4] = "Take a chill pill, <target>",
		[5] = "That's just cold, <target>.  Just plain cold",
		[6] = "And thats how I killed the dinosaurs",
		[7] = "Why so blue, <target>?",
		[8] = "Enjoy your 'You can't do that while frozen' messages",
		[9] = "Iceberg! Dead ahead!",
		[10] = "I don't know how we're gonna get <target> thawed!",
	};
	CRYOLYSIS_SHORT_MESSAGES = {
		[1] = "--> Opening a portal to <portal> <--",
		[2] = "Polymorph ==> <target>",
	};

end

-------------------------------------
--  VERSION FRANCAISE --
-------------------------------------

function Cryolysis_Localization_Speech_Fr()

	CRYOLYSIS_TELEPORT_MESSAGE = {
    [1] = "Si vous me cherchez, je suis \195\160 <portal>",
	[2] = "Bon je vous lache, on m'attend \195\160 <portal>",
	}
	CRYOLYSIS_PORTAL_MESSAGE = {
    [1] = "Passez votre permis, j'en ai marre de faire le taxi!",
	[2] = "Avec Mago Express, pas de stress, vous serez \195\160 <portal> en moins de temps qu'il n'en faut pour le taper.",
	[3] = "Envie de changer d'air? go <portal>",
	[4] = "Et hop, une faille spatio-temporelle vers <portal>",
	[5] = "R\195\169p\195\169tez apr\195\168s moi : Mago is good :p",
	}
	CRYOLYSIS_POLY_MESSAGE = {
		["Sheep"] = {
			[1] = "<target> va passer un quart d'heure \195\160 brouter...",
			[2] = "Proverbe ancien : Zoner un mouton, c'est devenir un mouton, compris?",
			[3] = "Je moutonne <target>, touchez y et je vous transforme en c\195\180ne glac\195\169.",
			[4] = "Par Magmadar et Lucifron, <target> est maintenant un mouton!",
			[5] = "Je moutonne <target>, PAS TOUCHE!",
			[6] = "M�me un murloc est mignon une fois mouton.",
			[7] = "Quelqu'un a besoin de chaussettes en laine pour cet hiver?",
			[8] = "Ok <target> r\195\169p\195\168te apr\195\168s moi : B\195\168\195\168\195\168\195\168\195\168\195\168",
			[9] = "Moutonnage de >> <target> <<. Pour chaque mouton frapp\195\169, 10po revers\195\169es \195\160 mon humble personne.",
			[10] = "Moutonnage de <target>:  Casseurs, Tankeurs!",
			[11] = "<target> est d\195\169sormais une boule de laine sur pattes!",
			[12] = "Vous voulez voir <target> descendre tout en bas de la cha\195\174ne alimentaire?",
			[13] = "<target> est un mouton mais ne le sait pas encore...",
			[14] = "Mouton, gentil mouton, ne me dis pas non.",
			[15] = "Ce mouton sera le chef d'oeuvre de ma carri\195\168re",
		},
		["Pig"] = {
			[1] = "Dans <target> tout est bon",
			[2] = "Cochonnage de <target>.  Oink! Oink!",
			[3] = "Ce soir : jambon beurre, c'est ma tourn\195\169e!",
			[4] = "Je pose un groin sur <target> et je suis \195\160 vous",
			[5] = "<target> est d\195\169sormais un m\195\169chouis sur pattes!",
			[6] = "Merci <target>, \195\167a ira.",
		},
		["Turtle"] = {
			[1] = "Dans la s\195\169rie des m\195\169tamorphoses loufoques, je voudrais la tortue",
			[2] = "<target> est parti \195\160 point",
			[3] = "Vous voulez voir un truc vraiment effrayant?",
			[4] = "<target> va passer le mur du son!",
		},
	}
	CRYOLYSIS_STEED_MESSAGE = {
	[1] = "Bon on va pas y passer la journ\195\169e ..",
	}
	CRYOLYSIS_SHORT_MESSAGES = {
		[1] = "--> Ouverture du portail vers <portal> <--",
		[2] = "Mouton ==> <target>",
	};

end


-------------------------------------
--  VERSION GERMAN -
-------------------------------------

function Cryolysis_Localization_Speech_De()

	CRYOLYSIS_TELEPORT_MESSAGE = {
  		[1] = "Ich gehe direkt nach <portal>! und ihr k\195\182nnt mich nicht mehr aufhalten!",
		[2] = "Oh ich muss weg!. Ich muss JETZT nach <portal>, zu einem Treffen. Dummes 'Magier Treffen' und so.",
		[3] = "Oh schau DA! Was ist das?! *WUSCH* Wo ist <player> hin? Buah hahaha. Schau doch mal in <portal>, ich bin wahrscheinlich beim H\195\164ndler.",
		[4] = "Woohoo! Ich fliege gerade mit dem <portal> Express! W\195\188rdest du nicht auch gerne 3 Ruhesteine haben?",
		[5] = "PS, seit ich mich nach <portal> porten kann, ist mein Ruhestein in Gadgetzan :P",
		[6] = "Bitte nicht meine Flugroute kreuzen!. Ich lande in <portal> in 10 Sekunden oder so.",
		[7] = "Ich hoffe diesmal habe ich richtig gezaubert! Das letzte Mal als ich nach <portal> wollte, waren meine Beine in Un�Goro und meine Arme in den Pestl\195\164ndern!",
	};
	CRYOLYSIS_PORTAL_MESSAGE = {
    		[1] = "Bitte einsteigen! Fliege mit <player>'s Flugservice direkt nach <portal>.",
		[2] = "Keine sorge ein klick auf das Portal bringt dich nach <portal>. Sicher!",
		[3] = "Chortle chortle, it's a portal!",
		[4] = "<player>'s Flugservice ist stolz euch einen Einweg-Elug nach <portal> anzubieten. Bitte schlie\195\159t die Augen beim Flug! Das kann verdammt unheimlich sein in einer H\195\182he von 10000 m",
		[5] = "BEKANNTMACHUNG: ICH HABE MEINE PORTAL-LIZENZ AUS DEM AH. KLICKEN AUF EIGENE GEFAHR!!",
		[6] = "Sicher, du kommst mit dem portal hier nach <portal>, aber willst du wirklich dahin?? Ich meine, wirklich <portal>? Was zur H\195\182lle ist falsch mit dir? Weisst du wer dort LEBT?",
		[7] = "Du magst dich nicht anstrengen um nach <portal> zu kommen? Dann klick hier drauf, du fauler Sack",
		[8] = "Ber\195\188hre/Betrete/Klettere durch mein magisches Loch!!!",
	}
	CRYOLYSIS_POLY_MESSAGE = {
		["Sheep"] = {
			[1] = "<target> war b\195\182se! M\195\132\195\132\195\132H!",
			[2] = "Und jetzt sprich mir nach, <target>: M\195\164\195\164\195\164h",
			[3] = "Verwandle <target>, schlag ihn und ich schlage dich!.",
			[4] = "Blauer Himmel gr\195\188nes Gras, <target> ist nun ein Schaf!",
			[5] = "Verwandle <target>, NICHT MEIN MITTAGESSEN HAUEN BITTE!",
			[6] = "Verwandle <target>! Lass die Finger davon! ",
			[7] = "Bleibt weg vom Schaf, ich brauche immer noch Mats f\195\188r [Woll-Str\195\188mpfe]",
			[8] = "Okay, versuch das nochmal!. M\195\164\195\164\195\164\195\164h",
			[9] = "Verwandle >> <target> <<. Jedesmal wenn du ein Schaf schl\195\162gst, t\195\182tet Gott ein K\195\164tzchen.",
			[10] = "Verwandle <target>!  wenn du es haust, musst du es Tanken.",
			[11] = "<target> ist mein Schaf. Es gibt viele andere wie es, aber dieses ist meins.",
			[12] = "Verwandle <target>, Bitte behaltet eure Hosen an!.",
			[13] = "M\195\164\195\164h, M\195\164\195\164h, <target>.  Kann ich etwas Wolle haben?",
			[14] = "Verwandle <target> weil Schafe nicht nein sagen k\195\182nnen.",
			[15] = "Verwandle <target>. Wiederholtes dr\195\188cken kann Explosionen verursachen!",
		},
		["Pig"] = {
			[1] = "HEY DA! Hier Schweinchen <target>. Ich will deinen Speck!",
			[2] = "Verwandle <target>.  Oink! Oink!",
			[3] = "SCHINKEN SANDWICHES!!",
			[4] = "Ich rieche Speck, Ich rieche Schwein, pass auf <target> dein Schinken ist mein!",
			[5] = "<target>:  Das etwas andere Schwein.",
			[6] = "Es wirkt, <target>.  Es wirkt!.",
			[7] = "Ruft bitte schonmal jemand den Schlachter?",
		},
		["Turtle"] = {
			[1] = "LOS MEINE SCHILDKR\195\150TE!",
			[2] = "Langsam und gem\195\188tlich^^! <target> gewinnt heute keine Rennen!",
			[3] = "Hey <target>, magst du Suppe? =D",
			[4] = "Was ist klein, gr�n und muss im Dreck kriechen? Richtig, es ist <target>!",
		},
	}
	CRYOLYSIS_STEED_MESSAGE = {
	[1] = "Mein Mount ist Cool!  Ihr seid doch nur eifers\195\188chtig weil ihr keinen <mount> habt",
	[2] = "Mein <mount> hat mein ganzes Brot gegessen und das ganze Wasser getrunken. Ich sollte neues holen...",
	}
	CRYOLYSIS_SHORT_MESSAGES = {
		[1] = "--> \195\15ffne ein Portal nach <portal> <--",
		[2] = "Verwandle ==> <target>",
	};
end

---------------------------------
-- TRADITIONAL CHINESE VERSION --
---------------------------------

function Cryolysis_Localization_Speech_Tw()

	CRYOLYSIS_TELEPORT_MESSAGE = {
		[1] = "我正在把自己傳送到<portal>！請勿打斷我喔！",
		[2] = "我感應到某些東西，我必須立刻前往 <portal>。",
		[3] = "我要飛回<portal>了！還有要我幫忙的地方嗎？",
		[4] = "看來我該回<portal>了,時間就是金錢，朋友！",
		[5] = "傳送術開始施展，十秒之後我將回到<portal>。",
		[6] = "希望這次可以正確的傳送到<portal>！",
	};
	CRYOLYSIS_PORTAL_MESSAGE = {
		[1] = "<player>開始提供航空服務，本班機10秒後即將飛往<portal>，持續時間一分鐘。",
		[2] = "前往<portal>的旅客請注意！傳送門即將開啟,欲前往的旅客請於一分鐘內點門。",
		[3] = "快看阿！有個<portal>傳送門耶！",
		[4] = "恭喜你得到了前往<portal>的單程機票～",
		[5] = "聲明：我的傳送門執照快過期了，點門的自行負責",
		[6] = "快點<portal>阿！要確定就是<portal>喔？",
		[7] = "做好準備前往<portal>了嗎？？點門！你就會飛過去了.....",
		[8] = "你緊握著雙手喃喃唸著不知名的咒語，面前的魔法六角星發出強烈的藍光，你的四周突然一陣模糊不清，轉眼間你就消失了。",
	};
	CRYOLYSIS_POLY_MESSAGE = {
		["Sheep"] = {
			[1] = "<target>變成一之羊咩咩了！",
			[2] = "我是牧羊人，別搞我的羊！",
			[3] = "正在將<target>變羊",
			[4] = "你是羊，你是洋，<target>現在是隻羊！",
			[5] = "正在將<target>變羊！攻擊前請確認！",
			[6] = "遠離我的羊，我還需要『羊毛衫』。",
			[7] = "%t注意聽著，重複我說的話。咩....",
			[8] = " >> <target> <<被變羊了，請勿隨意打羊！",
			[9] = "<target>是隻羊！  打到自己頂阿.....",
			[10] = "<target>是我的小綿羊，也許有其他長的很像的，可是這一隻有寫名字！",
			[11] = "咩....咩....<target>，有人需要羊毛嗎？?",
			[12] = "<target>，美味可口的燉羊肉喔...",
			[13] = "變形術施展在<target>身上，別輕易觸碰會發生危險的！",
		},
		["Pig"] = {
			[1] = "Sooooo Weeeeee! 這裡有隻小豬 <target>，別偷走這塊肥肉！",
			[2] = "肥美的豬肉<target>....  Oink! Oink!",
			[3] = "<target> - 美味可口的火腿培根三明治喔！",
			[4] = "<target>：新鮮的豬肉...",
			[5] = "我低沉的吟誦著咒語，在聖潔光輝的指引下，<target>將變成一頭溫馴的小豬！",
			[6] = "天靈靈地靈靈，<target>顯出原形！",
		},
		["Turtle"] = {
			[1] = "來吧，傑尼龜！",
			[2] = "<target>朋友，你又要給我們講你和兔子賽跑的故事了？",
			[3] = "Hey <target>，聽說你也會使盾牆？",
		},
	};
	CRYOLYSIS_STEED_MESSAGE = {
	[1] = "如果不是為了這個<mount>，我就不會在大學多呆一年了。",
	[2] = "旅遊指南說要帶上水、麵包和什麼來著？哦，<mount>！",
	[3] = "我的<mount>又吃光了我的麵包！只好再做點了……",
	};
	CRYOLYSIS_SHORT_MESSAGES = {
		[1] = "--> 正開啟傳送門前往 <portal> <--",
		[2] = "變形中 ==> <target>",
	};

end


--------------------------------
-- SIMPLIFIED CHINESE VERSION --
--------------------------------

function Cryolysis_Localization_Speech_Cn()

	CRYOLYSIS_TELEPORT_MESSAGE = {
		[1] = "我正在传送自己到<portal>，请不要打断我哦。",
		[2] = "我想起我还有点事，我必须立即前往<portal>。",
		[3] = "555，装备都坏了。我先回<portal>了哦，去修装备的地方找我。",
		[4] = "我要飞回<portal>了。还有需要我帮忙的地方吗？",
		[5] = "哈哈，因为我可以飞往<portal>，我的炉石就可以绑定到其他地方啦！",
		[6] = "请不要进入我的领空。10秒后我将起飞前往<portal>。",
		[7] = "希望这次我念对了咒语。上次我本想飞往<portal>，结果残骸撒遍了整个艾泽拉斯！",
	};
	CRYOLYSIS_PORTAL_MESSAGE = {
		[1] = "快来体验<player>航空公司的优质服务，本班机前往<portal>。",
		[2] = "注意：点击本传送门并不保证您能够安全到达<portal>。",
		[3] = "快看啊！有个传送门！",
		[4] = "<player>航空公司很荣幸为您提供前往<portal>的单程飞行服务。为了避免晕机，飞行期间请您闭上眼睛。",
		[5] = "郑重声明：我的飞行执照已经过期了。上了飞机风险自负！",
		[6] = "快点<portal>啊，要确定就是<portal>哦。",
		[7] = "做好准备前往<portal>了吗？点门，一眨眼功夫你就到啦！",
	};
	CRYOLYSIS_POLY_MESSAGE = {
		["Sheep"] = {
			[1] = "<target>变成羊咩咩了！",
			[2] = "我是牧羊人！不要碰我的羊！",
			[3] = "正在将<target>变羊，谁打我打断谁的腿。",
			[4] = "天苍苍野茫茫，<target>快变羊！",
			[5] = "正在将<target>变羊，不要攻击哦！",
			[6] = "正在将<target>变羊，欢迎你来打！？",
			[7] = "不要打我的羊哦！我要把它养大了好剪毛织毛衣呢。",
			[8] = "%t听着！重复我说的话：咩！",
			[9] = "正在将<target>变羊！谁打谁自己扛着！",
		},
		["Pig"] = {
			[1] = "天灵灵地灵灵，<target>显原形！",
			[2] = "正在将<target>变猪。呼噜！呼噜！",
			[3] = "猪排三明治！",
			[4] = "就是这样，<target>。就是这样。",
			[5] = "",
		},
		["Turtle"] = {
			[1] = "来吧，杰尼龟！",
			[2] = "<target>朋友，你又要给我们讲你和兔子赛跑的故事了？",
			[3] = "Hey <target>，听说你也会使盾墙？",
		},
	};
	CRYOLYSIS_STEED_MESSAGE = {
	[1] = "如果不是为了这个<mount>，我就不会在大学多呆一年了。",
	[2] = "旅游指南说要带上水、面包和什么来着？哦，<mount>！",
	[3] = "我的<mount>又吃光了我的面包！只好再做点了……",
	};
	CRYOLYSIS_SHORT_MESSAGES = {
		[1] = "--> 正在开启到<portal>的传送门 <--",
		[2] = "变羊 ==> <target>",
	};

end

-- Pour les caract鳥s spꤩaux :
-- Besondere Zeichen :
-- 頽 \195\169 ---- 蠽 \195\168
-- ࠽ \195\160 ---- ⠽ \195\162
-- 䠽 \195\180 ---- ꠽ \195\170
-- 렽 \195\187 ---- 䠽 \195\164
-- Ġ= \195\132 ---- 栽 \195\182
-- ֠= \195\150 ---- 젽 \195\188
-- ܠ= \195\156 ---- ߠ= \195\159
-- 砽 \195\167 ----  \195\174

