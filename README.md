# Advanced Random

An addon including a class that provides various functions that go beyond randf() and randi() to provide various kinds of RNG.

The highlight is the Dynamic Wheel of Fortune, introducing weighted randomness with weights calculated based on the contents of a collection: requirements, limits and buffs. This is perfect for games presenting a selection of random upgrades which may require other upgrades to provide any use. The `DynamicWheelItem` allows defining the item's weights, categories/tags, conditional weight bonuses and count limits.

Includes classes (each instantiated through `Class.new()` unless a Resource):
- `FortuneWheel`, a class providing the above described feature as well as simple weighted RNG;
- `FairNG`, a random number generator distributing numbers more evenly so things feel more "Fair" for the player;
- `DiceArray`, a class taking several of an `AdvancedDie` Resource to roll them and tally up the symbols that were rolled (as in the game [Circadian Dice](https://store.steampowered.com/app/1893620/Circadian_Dice/) or whatever has different symbols on one die face);
- `CardDeck`, a class that emulates drawing from a pile of cards. Implementation close to [Slay the Spire](https://store.steampowered.com/app/646570/Slay_the_Spire/) - when you draw from `PILE_DRAW`, cards go to `PILE_IN_PLAY` until you move them to `PILE_DISCARD`. More custom piles can be added and existing ones reconfigured.

#
Made by Don Tnowe in 2022.

https://redbladegames.netlify.app

https://twitter.com/don_tnowe

Copying and Modification is allowed in accordance to the MIT license, full text is included.
