# Flask: Alchemy of the four Elements

A open source collectable card game

## State of the project

The project is still in an early alpha state. Thats why the description is mostly in german. In a later state the cards and the rules will be available in englisch and german.

## Spielaufbau

* Alle Teilnehmenden erhalten vier Würfel die als Counter fungieren. Die Würfel representieren den Ressourcen stand von 💥Rot, 📘Blau, 💚Grün und 💰Gelb.
* Die Teilnehmenden bekommen jeweils ein Deck bestehend aus 15 Karten, die nun gemischt werden und als Nachziehstabel vor sie gelegt werden.
* Zu Beginn ziehen alle 3 Karten vom Nachziehstapel

## Spielziel

* Ziel des Spieles ist es alle gegnerischen Counter auf Null zu bringen.
* Alternative hat ein\*e Teilnehmer\*in verloren, sobald der eigene Nachziehstapel am Anfang der eingenen Runde aufgebraucht ist.

## Spielablauf

1. Ein beliebiger eigener Counter wird um 1 erhöht. **(Außer im ersten Zug des Spieles)**
2. Nun dürfen beliebig viele Handkarten gespielt, die Kosten dafür gezahlt und die jeweiligen Effekte ausgeführt werden.
3. Um den Zug zu beenden wird eine Karte vom Nachziehstapel gezogen.
4. Alle in diesem Zug gespielten Karten werden anschließend auf den Ablegestapel gelegt, **in der Reihenfolge wie sie gespielt wurden**.
5. Nun ist di\*er Teilnehmende zur Linken (Uhrzeigersinn) an der Reihe.

## Counter

* Die Counter besitzen ein Maximum von 6 und ein Minimum von 0.
* Geht ein Counter unter 0, so wird er auf 0 zurückgesetzt.
* **Der Counter darf innerhalb eines Zuges über 6 hinaus gehen**, am Ende verfällt allerdings alles was 6 übersteigt.

## Karte Spielen

* Um eine Karte zu spielen müssen zuerst die Kosten gezahlt werden. Dies geschieht durch das verändern der Counter.
* Anschließend wird der Effekt der Karte aktiviert. Und tritt sofort ein.
* Die gespielte Karte bleibt bis zum Ende des Zugen vor der\*m Teilnehmenden liegen.

## Deck bauen

* Ein Deck besteht auf 15 Karten
* Jede Karte ist aus Basiskarten zusammengesetzt, hierfür kann der [Online-Editor](https://orasund.github.io/flask/) benützt werden.
* Eine Karte darf bis zu 3 Mal in einem Deck erscheinen. Ein gewöhnliches Deck ist demnach auf 5 verschiedenen Karten aufgebaut.

## Effektivität der Karten-Decks

|         |💥|📘|💚|💰|
|Gegen 💥|   |  |👎|👍|
|Gegen 📘|   |  |👍|👎|
|Gegen 💚|👍|👎|  |  |
|Gegen 💰|👎|👍|  |   |