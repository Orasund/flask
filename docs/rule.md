# Rules (Version 0.4.X)

## Setup

* All Players start with four Counters each starting with 3. These counters represent the amount of resources. Resources are: 💥red, 📘blue, 💚green and 💰yellow.
* Each player has a deck existing of 15 cards. These are now shuffled and placed in front of said player.
* At the beginning of the game, each player draws 3 cards from the deck.

## Objective

* Once all enemy counters reach 0, the game is won.
* Alternatively a game is lost once the deck is empty at the beginning of the own turn.

## How to play

The game is turn-based and is played clock wise. A turn consists of four phases:

1. **Increasing a counter:** One of the own counters may be increased by one. **(Exept in the first round of the beginning player)**
2. **Playing cards:** Cards in the hand may be played, if the coresponding costs are payed. The cost are displayed at the top of the card. See _Playing a card_ for further information.
3. **Ending the turn:** To end a turn, draw a card.
4. **cleaning up:** Once the game has ended, place all placed cards on the discard pile. The order in which the cards where played must be preserved.

### Counter

* The counters can never go below 0 and **may exceed the maximal amount of 6 during a turn**, all remaining resources will be lost.

### Playing a card

* To play a card the name must be read out loud and the card must be displayed on the table, for everyone to see.
* Now the costs of the card, written on top (❔ symbolized an arbitary resource), will be payed.
* Finally the Cards gets activated and the effect gets executed.

So called _Reaction cards_ have a special rule:

* Once a raction card is placed face down on the table, it can be played any time (in particular during the enemy turn). This must happen before the cost of the card are fully payed.
* Once the reaction card is activated the effect will be executed **before** the enemy card is played, essentially blocking.
* If costs have already been payed, they need to be returned.

## Creating a Deck

* A deck consists of 15 cards
* Each card is compositioned from base cards. This can be easly done by using the [online card editor](https://orasund.github.io/flask/).
* A deck can only contain at most 3 similar cards. Two cards are similar if the codes on the bottom left corner are the same.

### Strengths and Weaknesses of different decks

|         |💥|📘|💚|💰|
|---------|--|--|---|--|
|Gegen 💥|   |  |👎|👍|
|Gegen 📘|   |  |👍|👎|
|Gegen 💚|👍|👎|  |  |
|Gegen 💰|👎|👍|  |   |

### Card Effects

* **Draw X Cards** Draw `X` cards from the discard pile and/or the own deck.
* **+📘📘 (+💰💰💰)** Add 📘📘 (💰💰💰) to your counters. At the end of your turn, your counter may  only cary a maximum of 6, all further resources will be lost.
* **Action: -X Resources** An enemy loses X resources of the own choosing. The Game is lost if at the end of any turn no resources are left.
* **Action: -X Cards** An enemy discards X cards of the own choosing. Has the player not enough card, then the remaining will be discarded from the top of the deck. The enemy has 
lost if no card remains in the deck at begining of the own deck.
* **+2 Resources of one kind** Add 📘📘, 💰💰, 💥💥 or 💚💚 to your counter.
* **Reboot** Return cards back into you hand, that have been played during this turn. 
Including this one.
* **Reaction** This card will be played face down and stays in the game until activated. All 
further cards, that will be placed under this one. This card can be activated at
any time and with it all cards below it will be activated as well.

### Licence

![https://i.creativecommons.org/l/by-nc/4.0/88x31.png]

This game is licenced under a [Attribution-Non Commercial 4.0 International license](https://creativecommons.org/licenses/by-nc/4.0/).
