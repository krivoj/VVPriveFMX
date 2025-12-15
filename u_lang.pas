unit u_lang;

interface

uses
  System.SysUtils, System.Classes;

// ⚠️ BASELINE INTOCCABILE
// Tutto ciò che segue è SOLO AGGIUNTA, nulla viene rimosso o modificato

// -----------------------------------------------------------------------------
// Lingue supportate
// -----------------------------------------------------------------------------
type
  TLang = (
    lgIT, // Italiano
    lgEN, // Inglese
    lgFR, // Francese
    lgDE, // Tedesco
    lgES, // Spagnolo
    lgRU  // Russo (al posto del Portoghese)
  );

const
  LANG_COUNT = 6;

// -----------------------------------------------------------------------------
// Struttura base per le stringhe traducibili
// -----------------------------------------------------------------------------
type
  TLangArray = array[TLang] of string;

// -----------------------------------------------------------------------------
// Variabili stringhe
// -----------------------------------------------------------------------------
var
  STR_YES, STR_NO: TLangArray;
  STR_ON, STR_OFF, STR_ALARM: TLangArray;
  STR_PRIV_DURATION_TITLE: TLangArray;
  STR_NO_GIRLS_IN_PRIVE: TLangArray;
  STR_SELECT_GIRL: TLangArray;
  STR_CLEAR_ACTIVITIES: TLangArray;
  STR_ADD_GIRL: TLangArray;
  STR_PRINT_ACTIVITIES: TLangArray;
  STR_EXIT: TLangArray;
  STR_MAX_GIRLS_PRIVE: TLangArray;
  STR_PRIVE_ACTIVE_NO_ADD: TLangArray;
  STR_PRIVE_SHORT_CONFIRM: TLangArray;
  STR_DELETE_GIRL_CONFIRM: TLangArray;
  STR_CANNOT_REMOVE_ACTIVE: TLangArray;
  STR_ADD_GIRL_TITLE: TLangArray;
  STR_ENTER_NAME: TLangArray;
  STR_INVALID_NAME: TLangArray;
  STR_GIRL_ALREADY_EXISTS: TLangArray;
  STR_MAX_GIRLS_TOTAL: TLangArray;
  STR_CLEAR_ALL_CONFIRM: TLangArray;
  STR_ACTIVITIES_RESET: TLangArray;
  STR_CANCEL, STR_OK_ADD, STR_OK_CONFIRM,STR_PRIVE: TLangArray;
  CurrentLang: TLang = lgIT;

// -----------------------------------------------------------------------------
// STRINGS PER u_ActivitiesDialog
// -----------------------------------------------------------------------------
  STR_ACTIVITY_LOG_TITLE: TLangArray;          // Registro attività privè – singola ragazza
  STR_ACTIVITY_LOG_COMPLETE_TITLE: TLangArray;// Registro completo attività privè
  STR_PRINT: TLangArray;                       // Pulsante stampa
  STR_CLOSE: TLangArray;                       // Pulsante chiudi
  STR_GIRL: TLangArray;                        // Ragazza
  STR_START: TLangArray;                       // Inizio
  STR_END: TLangArray;                         // Fine
  STR_DURATION: TLangArray;                    // Durata
// -----------------------------------------------------------------------------
// Helper
// -----------------------------------------------------------------------------
function L(const A: TLangArray): string;

implementation

function L(const A: TLangArray): string;
begin
  Result := A[CurrentLang];
end;

initialization
  // ---------------------------------------------------------------------------
// STR_YES / STR_NO
  STR_YES[lgIT] := 'SI';       STR_NO[lgIT] := 'NO';
  STR_YES[lgEN] := 'YES';      STR_NO[lgEN] := 'NO';
  STR_YES[lgFR] := 'OUI';      STR_NO[lgFR] := 'NON';
  STR_YES[lgDE] := 'JA';       STR_NO[lgDE] := 'NEIN';
  STR_YES[lgES] := 'SÍ';       STR_NO[lgES] := 'NO';
  STR_YES[lgRU] := 'ДА';       STR_NO[lgRU] := 'НЕТ';

  // STR_ON / STR_OFF
  STR_ON[lgIT] := 'ON';      STR_OFF[lgIT] := 'OFF';
  STR_ON[lgEN] := 'ON';      STR_OFF[lgEN] := 'OFF';
  STR_ON[lgFR] := 'ON';      STR_OFF[lgFR] := 'OFF';
  STR_ON[lgDE] := 'AN';      STR_OFF[lgDE] := 'AUS';
  STR_ON[lgES] := 'ON';      STR_OFF[lgES] := 'OFF';
  STR_ON[lgRU] := 'ВКЛ';     STR_OFF[lgRU] := 'ВЫКЛ';

    // STR_ALARM
  STR_ALARM[lgIT] := 'Allarme';
  STR_ALARM[lgEN] := 'Alarm';
  STR_ALARM[lgFR] := 'Alarme';
  STR_ALARM[lgDE] := 'Alarm';
  STR_ALARM[lgES] := 'Alarma';
  STR_ALARM[lgRU] := 'Сигнал тревоги';

  // STR_CANCEL / STR_OK_ADD
  STR_CANCEL[lgIT] := 'Annulla';      STR_OK_ADD[lgIT] := 'Aggiungi';
  STR_CANCEL[lgEN] := 'Cancel';       STR_OK_ADD[lgEN] := 'Add';
  STR_CANCEL[lgFR] := 'Annuler';      STR_OK_ADD[lgFR] := 'Ajouter';
  STR_CANCEL[lgDE] := 'Abbrechen';    STR_OK_ADD[lgDE] := 'Hinzufügen';
  STR_CANCEL[lgES] := 'Cancelar';     STR_OK_ADD[lgES] := 'Añadir';
  STR_CANCEL[lgRU] := 'Отмена';       STR_OK_ADD[lgRU] := 'Добавить';
// STR_OK_CONFIRM
  STR_OK_CONFIRM[lgIT] := 'Conferma';
  STR_OK_CONFIRM[lgEN] := 'Confirm';
  STR_OK_CONFIRM[lgFR] := 'Confirmer';
  STR_OK_CONFIRM[lgDE] := 'Bestätigen';
  STR_OK_CONFIRM[lgES] := 'Confirmar';
  STR_OK_CONFIRM[lgRU] := 'Подтвердить';

  STR_PRIVE[lgIT] := 'Privè';
  STR_PRIVE[lgEN] := 'Private';
  STR_PRIVE[lgFR] := 'Privé';
  STR_PRIVE[lgDE] := 'Separee';
  STR_PRIVE[lgES] := 'Reservado';
  STR_PRIVE[lgRU] := 'Приват';

  // ---------------------------------------------------------------------------
  // STR_PRIV_DURATION_TITLE
  STR_PRIV_DURATION_TITLE[lgIT] := 'Durata del Privè (minuti)';
  STR_PRIV_DURATION_TITLE[lgEN] := 'Privè duration (minutes)';
  STR_PRIV_DURATION_TITLE[lgFR] := 'Durée du privè (minutes)';
  STR_PRIV_DURATION_TITLE[lgDE] := 'Privè-Dauer (Minuten)';
  STR_PRIV_DURATION_TITLE[lgES] := 'Duración del privè (minutos)';
  STR_PRIV_DURATION_TITLE[lgRU] := 'Длительность приве (в минутах)';

  // ---------------------------------------------------------------------------
  // STR_NO_GIRLS_IN_PRIVE
  STR_NO_GIRLS_IN_PRIVE[lgIT] := 'Nel privè non sono presenti ragazze.';
  STR_NO_GIRLS_IN_PRIVE[lgEN] := 'There are no girls in the privè.';
  STR_NO_GIRLS_IN_PRIVE[lgFR] := 'Il n''y a aucune fille dans le privè.';
  STR_NO_GIRLS_IN_PRIVE[lgDE] := 'Im Privè sind keine Mädchen anwesend.';
  STR_NO_GIRLS_IN_PRIVE[lgES] := 'No hay chicas en el privè.';
  STR_NO_GIRLS_IN_PRIVE[lgRU] := 'В приве нет девушек.';

  // ---------------------------------------------------------------------------
  // STR_SELECT_GIRL
  STR_SELECT_GIRL[lgIT] := 'Seleziona una ragazza';
  STR_SELECT_GIRL[lgEN] := 'Select a girl';
  STR_SELECT_GIRL[lgFR] := 'Sélectionnez une fille';
  STR_SELECT_GIRL[lgDE] := 'Wähle ein Mädchen aus';
  STR_SELECT_GIRL[lgES] := 'Selecciona una chica';
  STR_SELECT_GIRL[lgRU] := 'Выберите девушку';

  // ---------------------------------------------------------------------------
  // STR_CLEAR_ACTIVITIES
  STR_CLEAR_ACTIVITIES[lgIT] := 'AZZERA ATTIVITA''';
  STR_CLEAR_ACTIVITIES[lgEN] := 'CLEAR ACTIVITIES';
  STR_CLEAR_ACTIVITIES[lgFR] := 'RÉINITIALISER ACTIVITÉS';
  STR_CLEAR_ACTIVITIES[lgDE] := 'AKTIVITÄTEN ZURÜCKSETZEN';
  STR_CLEAR_ACTIVITIES[lgES] := 'REINICIAR ACTIVIDADES';
  STR_CLEAR_ACTIVITIES[lgRU] := 'СБРОСИТЬ АКТИВНОСТИ';

  // ---------------------------------------------------------------------------
  // STR_ADD_GIRL
  STR_ADD_GIRL[lgIT] := 'AGGIUNGI RAGAZZA';
  STR_ADD_GIRL[lgEN] := 'ADD GIRL';
  STR_ADD_GIRL[lgFR] := 'AJOUTER FILLE';
  STR_ADD_GIRL[lgDE] := 'MÄDCHEN HINZUFÜGEN';
  STR_ADD_GIRL[lgES] := 'AÑADIR CHICA';
  STR_ADD_GIRL[lgRU] := 'ДОБАВИТЬ ДЕВУШКУ';

  // ---------------------------------------------------------------------------
  // STR_PRINT_ACTIVITIES
  STR_PRINT_ACTIVITIES[lgIT] := 'STAMPA ATTIVITA''';
  STR_PRINT_ACTIVITIES[lgEN] := 'PRINT ACTIVITIES';
  STR_PRINT_ACTIVITIES[lgFR] := 'IMPRIMER ACTIVITÉS';
  STR_PRINT_ACTIVITIES[lgDE] := 'AKTIVITÄTEN DRUCKEN';
  STR_PRINT_ACTIVITIES[lgES] := 'IMPRIMIR ACTIVIDADES';
  STR_PRINT_ACTIVITIES[lgRU] := 'ПЕЧАТЬ АКТИВНОСТЕЙ';

  // ---------------------------------------------------------------------------
  // STR_EXIT
  STR_EXIT[lgIT] := 'ESCI';
  STR_EXIT[lgEN] := 'EXIT';
  STR_EXIT[lgFR] := 'QUITTER';
  STR_EXIT[lgDE] := 'BEENDEN';
  STR_EXIT[lgES] := 'SALIR';
  STR_EXIT[lgRU] := 'ВЫХОД';

  // ---------------------------------------------------------------------------
  // STR_MAX_GIRLS_PRIVE
  STR_MAX_GIRLS_PRIVE[lgIT] := 'Massimo %d ragazze in un privè.';
  STR_MAX_GIRLS_PRIVE[lgEN] := 'Maximum %d girls in a private room.';
  STR_MAX_GIRLS_PRIVE[lgFR] := 'Maximum %d filles dans un privé.';
  STR_MAX_GIRLS_PRIVE[lgDE] := 'Maximal %d Mädchen im Separee.';
  STR_MAX_GIRLS_PRIVE[lgES] := 'Máximo %d chicas en un reservado.';
  STR_MAX_GIRLS_PRIVE[lgRU] := 'Максимум %d девушек в привате.';

  // ---------------------------------------------------------------------------
  // STR_PRIVE_ACTIVE_NO_ADD
  STR_PRIVE_ACTIVE_NO_ADD[lgIT] := 'Non puoi aggiungere una ragazza se il privè è attivo.';
  STR_PRIVE_ACTIVE_NO_ADD[lgEN] := 'You cannot add a girl while the private room is active.';
  STR_PRIVE_ACTIVE_NO_ADD[lgFR] := 'Impossible d''ajouter une fille si le privé est actif.';
  STR_PRIVE_ACTIVE_NO_ADD[lgDE] := 'Du kannst kein Mädchen hinzufügen, wenn das Separee aktiv ist.';
  STR_PRIVE_ACTIVE_NO_ADD[lgES] := 'No puedes añadir una chica si el reservado está activo.';
  STR_PRIVE_ACTIVE_NO_ADD[lgRU] := 'Нельзя добавить девушку, если приват активен.';

  // ---------------------------------------------------------------------------
  // STR_PRIVE_SHORT_CONFIRM
  STR_PRIVE_SHORT_CONFIRM[lgIT] := 'Il Privè è durato meno di 5 minuti. registro comunque l''attività?';
  STR_PRIVE_SHORT_CONFIRM[lgEN] := 'The private session lasted less than 5 minutes. Do you want to record it anyway?';
  STR_PRIVE_SHORT_CONFIRM[lgFR] := 'Le privé a duré moins de 5 minutes. Enregistrer quand même l''activité ?';
  STR_PRIVE_SHORT_CONFIRM[lgDE] := 'Das Separee dauerte weniger als 5 Minuten. Trotzdem speichern?';
  STR_PRIVE_SHORT_CONFIRM[lgES] := 'El reservado duró menos de 5 minutos. ¿Registrar igualmente la actividad?';
  STR_PRIVE_SHORT_CONFIRM[lgRU] := 'Приват длился менее 5 минут. Всё равно записать активность?';

  // ---------------------------------------------------------------------------
  // STR_DELETE_GIRL_CONFIRM
  STR_DELETE_GIRL_CONFIRM[lgIT] := 'Vuoi davvero cancellare questa ragazza: %s?';
  STR_DELETE_GIRL_CONFIRM[lgEN] := 'Do you really want to delete this girl: %s?';
  STR_DELETE_GIRL_CONFIRM[lgFR] := 'Voulez-vous vraiment supprimer cette fille : %s ?';
  STR_DELETE_GIRL_CONFIRM[lgDE] := 'Möchtest du dieses Mädchen wirklich löschen: %s?';
  STR_DELETE_GIRL_CONFIRM[lgES] := '¿Realmente quieres eliminar a esta chica: %s?';
  STR_DELETE_GIRL_CONFIRM[lgRU] := 'Вы действительно хотите удалить эту девушку: %s?';

  // ---------------------------------------------------------------------------
  // STR_CANNOT_REMOVE_ACTIVE
  STR_CANNOT_REMOVE_ACTIVE[lgIT] := 'Non puoi rimuovere una ragzza se il privè è attivo.';
  STR_CANNOT_REMOVE_ACTIVE[lgEN] := 'You cannot remove a girl while the private room is active.';
  STR_CANNOT_REMOVE_ACTIVE[lgFR] := 'Impossible de retirer une fille si le privé est actif.';
  STR_CANNOT_REMOVE_ACTIVE[lgDE] := 'Du kannst kein Mädchen entfernen, wenn das Separee aktiv ist.';
  STR_CANNOT_REMOVE_ACTIVE[lgES] := 'No puedes eliminar una chica si el reservado está activo.';
  STR_CANNOT_REMOVE_ACTIVE[lgRU] := 'Нельзя удалить девушку, если приват активен.';

  // ---------------------------------------------------------------------------
  // STR_ADD_GIRL_TITLE
  STR_ADD_GIRL_TITLE[lgIT] := 'Aggiungi ragazza, digita il nome.';
  STR_ADD_GIRL_TITLE[lgEN] := 'Add girl, enter the name.';
  STR_ADD_GIRL_TITLE[lgFR] := 'Ajouter une fille, entrez le nom.';
  STR_ADD_GIRL_TITLE[lgDE] := 'Mädchen hinzufügen, Namen eingeben.';
  STR_ADD_GIRL_TITLE[lgES] := 'Añadir chica, escribe el nombre.';
  STR_ADD_GIRL_TITLE[lgRU] := 'Добавить девушку, введите имя.';

  // ---------------------------------------------------------------------------
  // STR_ENTER_NAME
  STR_ENTER_NAME[lgIT] := 'Inserisci un nome.';
  STR_ENTER_NAME[lgEN] := 'Enter a name.';
  STR_ENTER_NAME[lgFR] := 'Entrez un nom.';
  STR_ENTER_NAME[lgDE] := 'Gib einen Namen ein.';
  STR_ENTER_NAME[lgES] := 'Introduce un nombre.';
  STR_ENTER_NAME[lgRU] := 'Введите имя.';

  // ---------------------------------------------------------------------------
  // STR_INVALID_NAME
  STR_INVALID_NAME[lgIT] := 'Inserisci un nome senza caratteri speciali.';
  STR_INVALID_NAME[lgEN] := 'Enter a name without special characters.';
  STR_INVALID_NAME[lgFR] := 'Entrez un nom sans caractères spéciaux.';
  STR_INVALID_NAME[lgDE] := 'Gib einen Namen ohne Sonderzeichen ein.';
  STR_INVALID_NAME[lgES] := 'Introduce un nombre sin caracteres especiales.';
  STR_INVALID_NAME[lgRU] := 'Введите имя без специальных символов.';

  // ---------------------------------------------------------------------------
  // STR_GIRL_ALREADY_EXISTS
  STR_GIRL_ALREADY_EXISTS[lgIT] := '%s è già presente';
  STR_GIRL_ALREADY_EXISTS[lgEN] := '%s already exists';
  STR_GIRL_ALREADY_EXISTS[lgFR] := '%s existe déjà';
  STR_GIRL_ALREADY_EXISTS[lgDE] := '%s ist bereits vorhanden';
  STR_GIRL_ALREADY_EXISTS[lgES] := '%s ya existe';
  STR_GIRL_ALREADY_EXISTS[lgRU] := '%s уже существует';

  // ---------------------------------------------------------------------------
  // STR_MAX_GIRLS_TOTAL
  STR_MAX_GIRLS_TOTAL[lgIT] := 'Puoi gestire al massimo %d ragazze';
  STR_MAX_GIRLS_TOTAL[lgEN] := 'You can manage up to %d girls';
  STR_MAX_GIRLS_TOTAL[lgFR] := 'Vous pouvez gérer au maximum %d filles';
  STR_MAX_GIRLS_TOTAL[lgDE] := 'Du kannst maximal %d Mädchen verwalten';
  STR_MAX_GIRLS_TOTAL[lgES] := 'Puedes gestionar un máximo de %d chicas';
  STR_MAX_GIRLS_TOTAL[lgRU] := 'Вы можете управлять максимум %d девушками';

  // ---------------------------------------------------------------------------
  // STR_CLEAR_ALL_CONFIRM
  STR_CLEAR_ALL_CONFIRM[lgIT] := 'Questa procedura termina ed azzera tutte le attività.' + sLineBreak + 'Vuoi procedere?';
  STR_CLEAR_ALL_CONFIRM[lgEN] := 'This procedure ends and clears all activities.' + sLineBreak + 'Do you want to continue?';
  STR_CLEAR_ALL_CONFIRM[lgFR] := 'Cette procédure termine et réinitialise toutes les activités.' + sLineBreak + 'Voulez-vous continuer ?';
  STR_CLEAR_ALL_CONFIRM[lgDE] := 'Dieser Vorgang beendet und setzt alle Aktivitäten zurück.' + sLineBreak + 'Möchtest du fortfahren?';
  STR_CLEAR_ALL_CONFIRM[lgES] := 'Este procedimiento finaliza y reinicia todas las actividades.' + sLineBreak + '¿Deseas continuar?';
  STR_CLEAR_ALL_CONFIRM[lgRU] := 'Эта процедура завершает и сбрасывает все активности.' + sLineBreak + 'Продолжить?';

  // ---------------------------------------------------------------------------
  // STR_ACTIVITIES_RESET
  STR_ACTIVITIES_RESET[lgIT] := 'ATTIVITA'' AZZERATE.' + sLineBreak + 'INIZIO SERATA.';
  STR_ACTIVITIES_RESET[lgEN] := 'ACTIVITIES RESET.' + sLineBreak + 'START OF THE EVENING.';
  STR_ACTIVITIES_RESET[lgFR] := 'ACTIVITÉS RÉINITIALISÉES.' + sLineBreak + 'DÉBUT DE SOIRÉE.';
  STR_ACTIVITIES_RESET[lgDE] := 'AKTIVITÄTEN ZURÜCKGESETZT.' + sLineBreak + 'ABEND BEGINNT.';
  STR_ACTIVITIES_RESET[lgES] := 'ACTIVIDADES REINICIADAS.' + sLineBreak + 'INICIO DE LA NOCHE.';
  STR_ACTIVITIES_RESET[lgRU] := 'АКТИВНОСТИ СБРОШЕНЫ.' + sLineBreak + 'НАЧАЛО ВЕЧЕРА.';

// STR_ACTIVITY_LOG_TITLE
  STR_ACTIVITY_LOG_TITLE[lgIT] := 'REGISTRO ATTIVITÀ PRIVÈ – %s';
  STR_ACTIVITY_LOG_TITLE[lgEN] := 'PRIVATE ROOM ACTIVITY LOG – %s';
  STR_ACTIVITY_LOG_TITLE[lgFR] := 'JOURNAL DES ACTIVITÉS DU PRIVÉ – %s';
  STR_ACTIVITY_LOG_TITLE[lgDE] := 'PRIVÈ-AKTIVITÄTSPROTOKOLL – %s';
  STR_ACTIVITY_LOG_TITLE[lgES] := 'REGISTRO DE ACTIVIDADES PRIVÉ – %s';
  STR_ACTIVITY_LOG_TITLE[lgRU] := 'РЕГИСТР АКТИВНОСТЕЙ ПРИВЕ – %s';

  // STR_ACTIVITY_LOG_COMPLETE_TITLE
  STR_ACTIVITY_LOG_COMPLETE_TITLE[lgIT] := 'REGISTRO COMPLETO ATTIVITÀ PRIVÈ';
  STR_ACTIVITY_LOG_COMPLETE_TITLE[lgEN] := 'COMPLETE PRIVATE ROOM ACTIVITY LOG';
  STR_ACTIVITY_LOG_COMPLETE_TITLE[lgFR] := 'JOURNAL COMPLET DES ACTIVITÉS DU PRIVÉ';
  STR_ACTIVITY_LOG_COMPLETE_TITLE[lgDE] := 'VOLLSTÄNDIGES PRIVÈ-AKTIVITÄTENPROTOKOLL';
  STR_ACTIVITY_LOG_COMPLETE_TITLE[lgES] := 'REGISTRO COMPLETO DE ACTIVIDADES PRIVÉ';
  STR_ACTIVITY_LOG_COMPLETE_TITLE[lgRU] := 'ПОЛНЫЙ РЕГИСТР АКТИВНОСТЕЙ ПРИВЕ';

  // STR_PRINT
  STR_PRINT[lgIT] := 'Stampa';
  STR_PRINT[lgEN] := 'Print';
  STR_PRINT[lgFR] := 'Imprimer';
  STR_PRINT[lgDE] := 'Drucken';
  STR_PRINT[lgES] := 'Imprimir';
  STR_PRINT[lgRU] := 'Печать';

  // STR_CLOSE
  STR_CLOSE[lgIT] := 'Chiudi';
  STR_CLOSE[lgEN] := 'Close';
  STR_CLOSE[lgFR] := 'Fermer';
  STR_CLOSE[lgDE] := 'Schließen';
  STR_CLOSE[lgES] := 'Cerrar';
  STR_CLOSE[lgRU] := 'Закрыть';

  // STR_GIRL
  STR_GIRL[lgIT] := 'Ragazza';
  STR_GIRL[lgEN] := 'Girl';
  STR_GIRL[lgFR] := 'Fille';
  STR_GIRL[lgDE] := 'Mädchen';
  STR_GIRL[lgES] := 'Chica';
  STR_GIRL[lgRU] := 'Девушка';

  // STR_START
  STR_START[lgIT] := 'Inizio';
  STR_START[lgEN] := 'Start';
  STR_START[lgFR] := 'Début';
  STR_START[lgDE] := 'Start';
  STR_START[lgES] := 'Inicio';
  STR_START[lgRU] := 'Начало';

  // STR_END
  STR_END[lgIT] := 'Fine';
  STR_END[lgEN] := 'End';
  STR_END[lgFR] := 'Fin';
  STR_END[lgDE] := 'Ende';
  STR_END[lgES] := 'Fin';
  STR_END[lgRU] := 'Конец';

  // STR_DURATION
  STR_DURATION[lgIT] := 'Durata';
  STR_DURATION[lgEN] := 'Duration';
  STR_DURATION[lgFR] := 'Durée';
  STR_DURATION[lgDE] := 'Dauer';
  STR_DURATION[lgES] := 'Duración';
  STR_DURATION[lgRU] := 'Длительность';

end.



