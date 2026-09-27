# Przekazanie kontekstu do nowego czatu — Mukla Officer Suite

Przeczytaj ten plik wraz z `AGENTS.md` przed rozpoczęciem pracy. To jest skrót długiej rozmowy, nie dowód, że każda funkcja została potwierdzona w kliencie WoW. Aktualny kod i stan `git` są źródłem prawdy.

## Współpraca

- Rozmawiaj po polsku; użytkownik poprosił o żeńskie formy wypowiedzi.
- Gdy użytkownik mówi, że najpierw zbiera uwagi i każe czekać na „robimy”, nie badaj kodu, nie nagrywaj i nie zmieniaj plików do wyraźnego sygnału.
- Nie twierdź, że poprawka działa w WoW na podstawie samej inspekcji kodu. Oddziel wdrożenie od testu w grze. Nie żądaj logów ani pomiarów wydajności bez konkretnej potrzeby.
- Długi czat zacinał się użytkownikowi; nowy czat ma zachować zwięzłą komunikację i korzystać z tej notatki, a nie z domniemanej pamięci poprzedniej rozmowy.

## Projekt i stan

- Addon do WoW 1.12.1. Kod gry jest w `MuklaOfficerSuite/`; skrypt wdrożenia to `Deploy-Addon.ps1`.
- Architektura i wymagania wydajnościowe są w `AGENTS.md`. Nie dopisuj logiki funkcjonalnej do głównego pliku kompozycji.
- Drzewo robocze zawiera rozległe, niezacommitowane zmiany (w tym nowe katalogi modułów). Zachowaj je; nie resetuj ani nie nadpisuj niezwiązanych plików.
- Ostatni obszar prac: `MuklaOfficerSuite/Modules/MasterLootWindow.lua`. W kodzie znajdują się m.in. własne okno Master Loot, sesje łupu, Start/Stop rolling, Finish, Current rolls, Restore rolls, Raid roll, historia rund, lista kandydatów, pole czasu domyślnie 15 sekund i próby tooltipów. Ich działanie w grze wymaga osobnego potwierdzenia.
- Użytkownik testował wcześniej skórkę Classic, responsywny Raid Management, widok List/Groups, warningi, scrollbar i hover. Nie należy ponownie otwierać tych tematów bez nowego zgłoszenia.

## Nagrywanie ekranu — ważne

- Projekt ma własne skrypty diagnostyczne: `Tools/DiagnosticCaptureService.ps1` oraz `Tools/Toggle-DiagnosticCapture.ps1`; stan i klatki są w `Screenshots/`. Wcześniej używano też skrótu „MOS Screen Recording” do uruchomienia nagrywania. Przed użyciem sprawdź aktualny mechanizm i pliki stanu.
- Nie uruchamiaj OBS, nie przejmuj widocznego okna ani nie zmieniaj aplikacji na ekranie tylko dlatego, że użytkownik mówi „zacznij nagrywać”. Poprzednia próba otwarcia OBS była błędem; użytkownik wyraźnie to zakwestionował.
- Nagrywaj tylko na wyraźne żądanie. Potwierdź faktyczny start na podstawie pliku stanu, nie na podstawie samego uruchomienia procesu. Na żądanie zatrzymania zatrzymaj i potwierdź zapis. Skrypty wybierają monitor na podstawie położenia ekranów, więc przed następnym nagraniem sprawdź, czy to właściwy ekran.
- Nie zakładaj, że nagranie z poprzedniego czatu jest dostępne w nowym. Jeśli potrzebne są konkretne klatki, sprawdź `Screenshots/` albo poproś o właściwy materiał.

## Ostatnie uzgodnione zachowanie Master Loot

- Stop rolling: przerwanie i unieważnienie oddanych rolli z komunikatem; Finish: wcześniejsze zakończenie i wybór zwycięzcy.
- Wynik na wierszu przedmiotu ma używać ikonki nagrody zamiast długiego „Wins:”; pole czasu ma mieć pełną ramkę; okno Master Loot ma być kompaktowe.
- Historia i bieżące wyniki mają być przypisane do właściwego źródła łupu. Ze względu na niepewność identyfikacji ciała istnieje ręczne Restore rolls; nie przypisuj historii do potwora wyłącznie po nazwie lub ID typu potwora.
- Szczegóły kolejnych zmian sprawdzaj w aktualnym kodzie i pytaj użytkownika tylko wtedy, gdy brak decyzji naprawdę zmienia zachowanie.

## Start w nowym czacie

W pierwszej wiadomości nowego czatu użytkownik może wkleić: „Kontynuujemy Mukla Officer Suite. Przeczytaj `HANDOFF.md` i `AGENTS.md`, sprawdź bieżący stan repozytorium; nie uruchamiaj OBS ani nagrywania bez mojego polecenia. Poczekaj na nowe zadanie.”
