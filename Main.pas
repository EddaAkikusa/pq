unit Main;
{ copyright (c)2002 Eric Fredricksen all rights reserved }

{$mode delphi}

{$UNDEF LOGGING}

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, Buttons, ImgList, Menus;

const
  kFileExt = '.pq3';

type

  { TMainForm }

  TMainForm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Traits: TListView;
    Equips: TListView;
    Panel3: TPanel;
    Label3: TLabel;
    QuestBar: TProgressBar;
    Stats: TListView;
    Label2: TLabel;
    PlotBar: TProgressBar;
    Plots: TListView;
    Quests: TListView;
    Panel2: TPanel;
    Label4: TLabel;
    Spells: TListView;
    InventoryLabelAlsoGameStyle: TLabel;
    Inventory: TListView;
    Panel4: TPanel;
    Kill: TStatusBar;
    Label6: TLabel;
    ExpBar: TProgressBar;
    TaskBar: TProgressBar;
    Timer1: TTimer;
    EncumBar: TProgressBar;
    Label7: TLabel;
    Label8: TLabel;
    vars: TPanel;
    fTask: TLabel;
    fQuest: TLabel;
    fQueue: TListBox;
    procedure GoButtonClick(Sender: TObject);
    procedure PlotsItemChecked(Sender: TObject; Item: TListItem);
    procedure QuestsItemChecked(Sender: TObject; Item: TListItem);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    procedure Task(caption: String; msec: Integer);
    procedure Dequeue;
    procedure Q(s: string);
    function TaskDone: Boolean;
    procedure CompleteQuest;
    procedure CompleteAct;
    procedure WinEquip;
    procedure WinSpell;
    procedure WinStat;
    procedure WinItem;
    function SpecialItem: String;
    procedure LevelUp;
    function BoringItem: String;
    function InterestingItem: String;
    function MonsterTask(var level: Integer): String;
    function EquipPrice: Integer;
    procedure TriggerAutosizes;
    function GameSaveName: String;
    procedure ClearAllSelections;
    {$IFDEF LOGGING}
    procedure Log(line: String);
    {$ENDIF}
    procedure ExportCharSheet;
    function CharSheet: String;
    procedure InterplotCinematic;
    function NamedMonster(level: Integer): String;
    function ImpressiveGuy: String;
  public
    FReportSave: Boolean;
    FLogEvents: Boolean;
    FMakeBackups: Boolean;
    FExportSheets: Boolean;
    FSaveFileName: String;
    WorkDir: String;
    procedure LoadGame(name: String);
    function SaveGame: Boolean;
    procedure Put(list: TListView; key: String; value: String); overload;
    procedure Put(list: TListView; pos: Integer; value: String); overload;
    procedure Put(list: TListView; key: String; value: Integer); overload;
    procedure Add(list: TListView; key: String; value: Integer); overload;
    procedure AddR(list: TListView; key: String; value: Integer); overload;
    function Get(list: TListView; key: String): String; overload;
    function Get(list: TListView; index: Integer): String; overload;
    function GetI(list: TListView; key: String): Integer; overload;
    function GetI(list: TListView; index: Integer): Integer; overload;
    function Sum(list: TListView): Integer;
    function RollCharacter: Boolean;
  end;

var
  MainForm: TMainForm;

function Split(s: String; field: Integer): String; overload;
function Split(s: String; field: Integer; separator: String): String; overload;


implementation

uses StrUtils, NewGuy, Math, Config, Front, PasZLib;

{$R *.lfm}

procedure StartTimer;
begin
  if not MainForm.Timer1.Enabled then begin
    MainForm.Timer1.Tag := gettickcount64;
    //Shell_NotifyIcon(NIM_ADD, @MainForm.FTrayIcon);
  end;
  MainForm.Timer1.Enabled := True;
  // BS location for this, but...
  MainForm.Caption := 'ProgressQuest - ' + ChangeFileExt(ExtractFileName(MainForm.GameSaveName), '');
end;

procedure TMainForm.Q(s: string);
begin
  fQueue.Items.Add(s);
  Dequeue;
end;

function TMainForm.TaskDone: Boolean;
begin
  with TaskBar do
    Result := Position >= Max;
end;

function Odds(chance, outof: Integer): Boolean;
begin
  Result := Random(outof) < chance;
end;

function RandSign(): Integer;
begin
  Result := Random(2) * 2 - 1;
end;

function Pick(s: TStrings): String;
begin
  Result := s[Random(s.Count)];
end;

function RandomLow(below: Integer): Integer;
begin
  Result := Min(Random(below),Random(below));
end;

function PickLow(s: TStrings): String;
begin
  Result := s[RandomLow(s.Count)];
end;

function Ends(s,e: String): Boolean;
begin
  Result := Copy(s,1+Length(s)-Length(e),Length(e)) = e;
end;

function Plural(s: String): String;
begin
       if Ends(s,'y')
       then Result := Copy(s,1,Length(s)-1) + 'ies'
  else if Ends(s,'us')
       then Result := Copy(s,1,Length(s)-2) + 'i'
  else if Ends(s,'ch') or Ends(s,'x') or Ends(s,'s')
       then Result := s + 'es'
  else if Ends(s,'f')
       then Result := Copy(s,1,Length(s)-1) + 'ves'
  else if Ends(s,'man') or Ends(s,'Man')
       then Result := Copy(s,1,Length(s)-2) + 'en'
       else Result := s + 's';
end;

function Split(s: String; field: Integer; separator: String): String;
var
  p: Integer;
begin
  while field > 0 do begin
    p := Pos(separator,s);
    s := Copy(s,p+1,10000);
    Dec(field);
  end;
  if Pos(separator,s) > 0
  then Result := Copy(s,1,Pos(separator,s)-1)
  else Result := s;
end;

function Split(s: String; field: Integer): String;
begin
  result := Split(s, field, '|');
end;

function Indefinite(s: String; qty: Integer): String;
begin
  if qty = 1 then begin
    if Pos(s[1], 'AEIOUÜaeiouü') > 0
    then Result := 'an ' + s
    else Result := 'a ' + s;
  end else begin
    Result := IntToStr(qty) + ' ' + Plural(s);
  end;
end;

function Definite(s: String; qty: Integer): String;
begin
  if qty > 1 then
    s := {IntToStr(qty) + ' ' +} Plural(s);
  Result := 'the ' + s;
end;

function Sick(m: Integer; s: String): String;
begin
  Result := IntToStr(m) + s; // in case I screw up
  case m of
  -5,5: Result := 'dead ' + s;
  -4,4: Result := 'comatose ' + s;
  -3,3: Result := 'crippled ' + s;
  -2,2: Result := 'sick ' + s;
  -1,1: Result := 'undernourished ' + s;
  end;
end;

function Young(m: Integer; s: String): String;
begin
  Result := IntToStr(m) + s; // in case I screw up
  case -m of
  -5,5: Result := 'foetal ' + s;
  -4,4: Result := 'baby ' + s;
  -3,3: Result := 'preadolescent ' + s;
  -2,2: Result := 'teenage ' + s;
  -1,1: Result := 'underage ' + s;
  end;
end;

function Big(m: Integer; s: String): String;
begin
  Result := s; // in case I screw up
  case m of
  1,-1: Result := 'greater ' + s;
  2,-2: Result := 'massive ' + s;
  3,-3: Result := 'enormous ' + s;
  4,-4: Result := 'giant ' + s;
  5,-5: Result := 'titanic ' + s;
  end;
end;

function Special(m: Integer; s: String): String;
begin
  Result := s; // in case I screw up
  case -m of
  1,-1:
      if Pos(' ',Result) > 0
      then Result := 'veteran ' + s
      else Result := 'Battle-' + s;
  2,-2: Result := 'cursed ' + s;
  3,-3:
      if Pos(' ',Result) > 0
      then Result := 'warrior ' + s
      else Result := 'Were-' + s;
  4,-4: Result := 'undead ' + s;
  5,-5: Result := 'demon ' + s;
  end;
end;

procedure TMainForm.InterplotCinematic;
var
  nemesis: String;
  i, s: Integer;
begin
  case Random(3) of
  0: begin
    Q('task|1|Exhausted, you arrive at a friendly oasis in a hostile land');
    Q('task|2|You greet old friends and meet new allies');
    Q('task|2|You are privy to a council of powerful do-gooders');
    Q('task|1|There is much to be done. You are chosen!');
     end;
  1: begin
    Q('task|1|Your quarry is in sight, but a mighty enemy bars your path!');
    nemesis := NamedMonster(GetI(Traits,'Level')+3);
    Q('task|4|A desperate struggle commences with ' + nemesis);
    s := Random(3);
    for i := 1 to Random(1 + Plots.Items.Count) do begin
      Inc(s, 1 + Random(2));
      case s mod 3 of
      0: Q('task|2|Locked in grim combat with ' + nemesis);
      1: Q('task|2|' + nemesis + ' seems to have the upper hand');
      2: Q('task|2|You seem to gain the advantage over ' + nemesis);
      end;
    end;
    Q('task|3|Victory! ' + nemesis + ' is slain! Exhausted, you lose conciousness');
    Q('task|2|You awake in a friendly place, but the road awaits');
      end;
  2: begin
    nemesis := ImpressiveGuy;
    Q('task|2|Oh sweet relief! You''ve reached the protection of the good ' + nemesis);
    Q('task|3|There is rejoicing, and an unnerving encouter with ' + nemesis + ' in private');
    Q('task|2|You forget your ' + BoringItem + ' and go back to get it');
    Q('task|2|What''s this!? You overhear something shocking!');
    Q('task|2|Could ' + nemesis + ' be a dirty double-dealer?');
    Q('task|3|Who can possibly be trusted with this news!? ... Oh yes, of course');
      end;
  end;
  Q('plot|1|Loading');
end;


function TMainForm.NamedMonster(level: Integer): String;
var
  lev, i: Integer;
  m: String;
begin
  lev := 0;  // shut up, compiler hint
  for i := 1 to 5 do begin
    m := Pick(K.Monsters.Lines);
    if (Result = '') or (abs(level-StrToInt(Split(m,1))) < abs(level-lev)) then begin
      Result := Split(m,0);
      lev := StrToInt(Split(m,1));
    end;
  end;
  Result := GenerateName + ' the ' + Result;
end;

function TMainForm.ImpressiveGuy: String;
begin
  Result := Pick(K.ImpressiveTitles.Lines);
  case Random(2) of
  0: Result := Result + ' of the ' + Pick(K.Races.Lines);
  1: Result := Result + ' of ' + GenerateName;
  end;
end;

function TMainForm.MonsterTask(var level: Integer): String;
var
  qty, lev, i: Integer;
  monster, m1: string;
  definite: Boolean;
begin
  definite := false;
  for i := level downto 1 do begin
    if Odds(2,5) then
      Inc(level, RandSign());
  end;
  if level < 1 then level := 1;
  // level = level of puissance of opponent(s) we'll return

  if Odds(1,25) then begin
    // use an NPC every once in a while
    monster := ' ' + Pick(NewGuyForm.Race.Items);
    if Odds(1,2)
    then monster := 'passing' + monster + ' ' + Pick(NewGuyForm.Klass.Items)
    else begin
      monster := PickLow(K.Titles.Lines) + ' ' + GenerateName + ' the' + monster;
      definite := true;
    end;
    lev := level;
    monster := monster + '|' + IntToStr(level) + '|*';
  end else if (fQuest.Caption <> '') and Odds(1,4) then begin
    // use the quest monster
    monster := k.Monsters.Lines[fQuest.Tag];
    lev := StrToInt(Split(monster,1));
  end else begin
    // pick the monster out of so many random ones closest to the level we want
    monster := Pick(K.Monsters.Lines);
    lev := StrToInt(Split(monster,1));
    i := 5;
    while (i > 0) do begin // or (lev - level > 4) do begin
      m1 := Pick(K.Monsters.Lines);
      if abs(level-StrToInt(Split(m1,1))) < abs(level-lev) then begin
        monster := m1;
        lev := StrToInt(Split(monster,1));
      end;
      if i > 0 then Dec(i);
    end;
  end;

  fTask.Caption := monster;
  Result := Split(monster,0);
  fTask.Caption := 'kill|' + fTask.Caption;

  qty := 1;
  if (level-lev) > 10 then begin
      // lev is too low. multiply...
      qty := (level + Random(lev)) div max(lev,1);
      if qty < 1 then qty := 1;
      level := level div qty;
  end;

  if (level - lev) <= -10 then begin
    Result := 'imaginary ' + Result;
  end else if (level-lev) < -5 then begin
    i := 10+(level-lev);
    i := 5-Random(i+1);
    Result := Sick(i,Young((lev-level)-i,Result));
  end else if ((level-lev) < 0) and (Random(2) = 1) then begin
    Result := Sick(level-lev,Result);
  end else if ((level-lev) < 0) then begin
    Result := Young(level-lev,Result);
  end else if (level-lev) >= 10 then begin
    Result := 'messianic ' + Result;
  end else if (level-lev) > 5 then begin
    i := 10-(level-lev);
    i := 5-Random(i+1);
    Result := Big(i,Special((level-lev)-i,Result));
  end else if ((level-lev) > 0) and (Random(2) = 1) then begin
    Result := Big(level-lev,Result);
  end else if ((level-lev) > 0) then begin
    Result := Special(level-lev,Result);
  end;

  lev := level;
  level := lev * qty;

  if not definite then Result := Indefinite(Result, qty);
end;

function ProperCase(s:String):String;
begin
  Result := UpperCase(Copy(s,1,1)) + Copy(s,2,10000);
end;

function TMainForm.EquipPrice: Integer;
begin
  Result :=  5 * GetI(Traits,'Level') * GetI(Traits,'Level')
          + 10 * GetI(Traits,'Level')
          + 20;
end;

procedure TMainForm.Dequeue;
var
  s, a, old: String;
  n, l: Integer;
begin
  while TaskDone do begin
    if Split(fTask.Caption,0) = 'kill' then begin
      if Split(fTask.Caption,3) = '*' then begin
        WinItem;
      end else if Split(fTask.Caption,3) <> '' then begin
        Add(Inventory,LowerCase(Split(fTask.Caption,1) + ' ' + ProperCase(Split(fTask.Caption,3))),1);
      end;
    end else if fTask.Caption = 'buying' then begin
      // buy some equipment
      Add(Inventory,'Gold',-EquipPrice);
      WinEquip;
    end else if (fTask.Caption = 'market') or (fTask.Caption = 'sell') then with Inventory do begin
      if fTask.Caption = 'sell' then begin
        Tag := GetI(Inventory,1);
        Tag := Tag * GetI(Traits,'Level');
        if Pos(' of ',Items[1].Caption) > 0 then
          Tag := Tag * (1+RandomLow(10)) * (1+RandomLow(GetI(Traits,'Level')));
        Items[0].MakeVisible(false);
        Items.Delete(1);
        Add(Inventory,'Gold',Tag);
      end;
      if Items.Count > 1 then begin
        Task('Selling ' + Indefinite(Inventory.Items[1].Caption, GetI(Inventory,1)), 1 * 1000);
        fTask.Caption := 'sell';
        break;
      end;
    end;
    old := fTask.Caption;
    fTask.Caption := '';
    if (fQueue.Items.Count > 0) then begin
      a := Split(fQueue.Items[0],0);
      n := StrToInt(Split(fQueue.Items[0],1));
      s := Split(fQueue.Items[0],2);
      if (a = 'task') or (a = 'plot') then begin
        if a = 'plot' then begin
          CompleteAct;
          s := 'Loading ' + Plots.Items[Plots.Items.Count-1].Caption;
        end;
        Task(s, n * 1000);
        fQueue.Items.Delete(0);
      end else begin
        raise Exception.Create('bah!');
      end;
    end else with Encumbar do if Position >= Max then begin
      Task('Heading to market to sell loot',4 * 1000);
      fTask.Caption := 'market';
    end else if (Pos('kill|',old) <= 0) and (old <> 'heading') then begin
      if GetI(Inventory, 'Gold') > EquipPrice then begin
        Task('Negotiating purchase of better equipment', 5 * 1000);
        fTask.Caption := 'buying';
      end else begin
        Task('Heading to the killing fields', 4 * 1000);
        fTask.Caption := 'heading';
      end;
    end else begin
      n := GetI(Traits,'Level');
      l := n;
      s := MonsterTask(n);
      n := (2 * InventoryLabelAlsoGameStyle.Tag * n * 1000) div l;
      Task('Executing ' + s, n);
    end;
  end;
end;

function IndexOf(list: TListView; key: String): Integer;
var
  i: Integer;
begin
  for i := 0 to list.Items.Count-1 do    if list.Items.Item[i].Caption = key then begin
      Result := i;
      Exit;
    end;
  with list.Items.Add do begin
    Result := Index;
    Caption := key;
    MakeVisible(false);
    list.Width := list.Width - 1; // trigger an autosize
  end;
end;

procedure TMainForm.Put(list: TListView; key, value: String);
begin
  Put(list, IndexOf(list,key), value);
end;

procedure TMainForm.Put(list: TListView; key: String; value: Integer);
begin
  Put(list,key,IntToStr(value));
  if key = 'STR' then
    Encumbar.Max := 10 + value;
  if list = Inventory then with Encumbar do begin
    Position := Sum(Inventory) - GetI(Inventory,'Gold');
    Hint := IntToStr(Position) + '/' + IntToStr(Max) + ' cubits';
  end;
end;

procedure TMainForm.Put(list: TListView; pos: Integer; value: String);
begin
  with list.Items.Item[pos] do begin
    if SubItems.Count < 1
    then SubItems.Add(value)
    else SubItems[0] := value;
  end;
  //list.MultiSelect := true;
  //list.RowSelect := true;
  //list.HideSelection := false;
  list.Items[pos].Selected := true;
end;

function LevelUpTime(level: Integer): Integer;  // seconds
begin
  // 20 minutes per level
  Result := 20 * level * 60;
end;

procedure TMainForm.GoButtonClick(Sender: TObject);
begin
  with ExpBar do begin
    Position := 0;
    Max := LevelUpTime(1);
  end;

  fTask.Caption := '';
  fQuest.Caption := '';
  fQueue.Items.Clear;

  Task('Loading.',2000); // that dot is spotted for later...
  Q('task|10|Experiencing an enigmatic and foreboding night vision');
  Q('task|6|Much is revealed about that wise old bastard you''d underestimated');
  Q('task|6|A shocking series of events leaves you alone and bewildered, but resolute');
  Q('task|4|Drawing upon an unexpected reserve of determination, you set out on a long and dangerous journey');
  Q('task|2|Loading');

  PlotBar.Max := 26;
  with Plots.Items.Add do begin
    Caption := 'Prologue';
    Checked := False;
  end;

  StartTimer;
  SaveGame;
end;

procedure TMainForm.QuestsItemChecked(Sender: TObject; Item: TListItem);
begin  
  Quests.OnItemChecked := nil;
  Item.Checked := not Item.Checked;
  Quests.OnItemChecked := PlotsItemChecked;
end;

procedure TMainForm.PlotsItemChecked(Sender: TObject; Item: TListItem);
begin
  Plots.OnItemChecked := nil;
  Item.Checked := not Item.Checked;
  Plots.OnItemChecked := PlotsItemChecked;
end;

procedure TMainForm.WinSpell;
begin
  AddR(Spells, K.Spells.Lines[RandomLow(Min(GetI(Stats,'WIS')+GetI(Traits,'Level'),
                                            K.Spells.Lines.Count))], 1);
end;

function LPick(list: TStrings; goal: Integer): String;
var
  i, best, b1: Integer;
  s: String;
begin
  Result := Pick(list);
  for i := 1 to 5 do begin
    best := StrToInt(Split(Result,1));
    s := Pick(list);
    b1 := StrToInt(Split(s,1));
    if abs(goal-best) > abs(goal-b1) then
      Result := s;
  end;
end;

procedure TMainForm.WinEquip;
var
  posn, qual, plus, count: Integer;
  name, modifier: String;
  stuff, better, worse: TStrings;
begin
  posn := Random(Equips.Items.Count);
  Equips.Tag := posn; // remember as the "best item"
  if posn = 0 then begin
    stuff := K.Weapons.Lines;
    better := K.OffenseAttrib.Lines;
    worse := K.OffenseBad.Lines;
  end else begin
    better := K.DefenseAttrib.Lines;
    worse := K.DefenseBad.Lines;
    if posn = 1
    then stuff := K.Shields.Lines
    else stuff := K.Armors.Lines;
  end;
  name := LPick(stuff,GetI(Traits,'Level'));
  qual := StrToInt(Split(name,1));
  name := Split(name,0);
  plus := GetI(Traits,'Level') - qual;
  if plus < 0 then better := worse;
  count := 0;
  while (count < 2) and (plus <> 0) do begin
    modifier := Pick(better);
    qual := StrToInt(Split(modifier, 1));
    modifier := Split(modifier, 0);
    if Pos(modifier, name) > 0 then Break; // no repeats
    if Abs(plus) < Abs(qual) then Break; // too much
    name := modifier + ' ' + name;
    Dec(plus, qual);
    Inc(count);
  end;
  if plus <> 0 then name := IntToStr(plus) + ' ' + name;
  if plus > 0 then name := '+' + name;

  Put(Equips, posn, name);
end;

procedure TMainForm.WinStat;
var
  i,t: Integer;
  function Square(x: Integer): Integer; begin Result := x * x; end;
begin
  if Odds(1,2)
  then i := Random(Stats.Items.Count)
  else begin
    // favor the best stat so it will tend to clump
    t := 0;
    for i := 0 to 5 do Inc(t,Square(GetI(Stats,i)));
    t := Random(t);
    i := -1;
    while t >= 0 do begin
      Inc(i);
      Dec(t,Square(GetI(Stats,i)));
    end;
  end;
  Add(Stats, Stats.Items[i].Caption, 1);
end;

function TMainForm.SpecialItem: String;
begin
  Result := InterestingItem + ' of ' +
            Pick(K.ItemOfs.Lines);
end;

function TMainForm.InterestingItem: String;
begin
  Result := Pick(K.ItemAttrib.Lines) + ' ' +
            Pick(K.Specials.Lines);
end;

function TMainForm.BoringItem: String;
begin
  Result := Pick(K.BoringItems.Lines);
end;

procedure TMainForm.WinItem;
begin
  Add(Inventory, SpecialItem, 1);
end;

procedure TMainForm.CompleteQuest;
var
  lev, level, l, i, montag: Integer;
  m: string;
begin
  lev := 0;  // Quell stupid compiler warning
  with QuestBar do begin
    Position := 0;
    Max := 50 + Random(100);
  end;
  with Quests do begin
    if Items.Count > 0 then begin
      {$IFDEF LOGGING}
      Log('Quest completed: ' + Items[Items.Count-1].Caption);
      {$ENDIF}
      Items[Items.Count-1].Checked := TRUE;
      case Random(4) of
        0: WinSpell;
        1: WinEquip;
        2: WinStat;
        3: WinItem;
      end;
    end;
    while Items.Count > 99 do Items.Delete(0);

    with Items.Add do begin
      case Random(5) of
        0: begin
          level := GetI(Traits,'Level');
          for i := 1 to 4 do begin
            montag := Random(K.Monsters.Lines.Count);
            m := K.Monsters.Lines[montag];
            l := StrToInt(Split(m,1));
            if (i = 1) or (abs(l - level) < abs(lev - level)) then begin
              lev := l;
              fQuest.Caption := m;
              fQuest.Tag := montag;
            end;
          end;
          Caption := 'Exterminate ' + Definite(Split(fQuest.Caption,0),2);
        end;
        1: begin
          fQuest.Caption := InterestingItem;
          Caption := 'Seek ' + Definite(fQuest.Caption,1);
          fQuest.Caption := '';
        end;
        2: begin
          fQuest.Caption := BoringItem;
          Caption := 'Deliver this ' + fQuest.Caption;
          fQuest.Caption := '';
        end;
        3: begin
          fQuest.Caption := BoringItem;
          Caption := 'Fetch me ' + Indefinite(fQuest.Caption,1);
          fQuest.Caption := '';
        end;
        4: begin
          level := GetI(Traits,'Level');
          for i := 1 to 2 do begin
            montag := Random(K.Monsters.Lines.Count);
            m := K.Monsters.Lines[montag];
            l := StrToInt(Split(m,1));
            if (i = 1) or (abs(l - level) < abs(lev - level)) then begin
              lev := l;
              fQuest.Caption := m;
            end;
          end;
          Caption := 'Placate ' + Definite(Split(fQuest.Caption,0),2);
          fQuest.Caption := '';
        end;
      end;
      {$IFDEF LOGGING}
      Log('Commencing quest: ' + Caption);
      {$ENDIF}
      Checked := False;
      MakeVisible(false);
    end;
    Width := Width - 1; // trigger a column resize
  end;
  SaveGame;
end;

function Rome(var n: Integer; dn: Integer; var s: String; ds: String): Boolean;
begin
  Result := (n >= dn);
  if Result then begin
    n := n - dn;
    s := s + ds;
  end;
end;

function UnRome(var s: String; dn: Integer; var n: Integer; ds: String): Boolean;
begin
  Result := (Copy(s,1,Length(ds)) = ds);
  if Result then begin
    s := Copy(s,Length(ds)+1,10000);
    n := n + dn;
  end;
end;

function IntToRoman(n: Integer): String;
begin
  Result := '';
  while Rome(n, 1000, Result, 'M') do ;
  Rome(n, 900, Result, 'CM');
  Rome(n, 500, Result, 'D');
  Rome(n, 400, Result, 'CD');
  while Rome(n, 100, Result, 'C') do ;
  Rome(n, 90, Result, 'XC');
  Rome(n, 50, Result, 'L');
  Rome(n, 40, Result, 'XL');
  while Rome(n, 10, Result, 'X') do ;
  Rome(n, 9, Result, 'IX');
  Rome(n, 5, Result, 'V');
  Rome(n, 4, Result, 'IV');
  while Rome(n, 1, Result, 'I') do ;
end;

function RomanToInt(n: String): Integer;
begin
  Result := 0;
  while UnRome(n, 1000, Result, 'M') do ;
  UnRome(n, 900, Result, 'CM');
  UnRome(n, 500, Result, 'D');
  UnRome(n, 400, Result, 'CD');
  while UnRome(n, 100, Result, 'C') do ;
  UnRome(n, 90, Result, 'XC');
  UnRome(n, 50, Result, 'L');
  UnRome(n, 40, Result, 'XL');
  while UnRome(n, 10, Result, 'X') do ;
  UnRome(n, 9, Result, 'IX');
  UnRome(n, 5, Result, 'V');
  UnRome(n, 4, Result, 'IV');
  while UnRome(n, 1, Result, 'I') do ;
end;

procedure TMainForm.CompleteAct;
begin
  PlotBar.Position := 0;
  with Plots do begin
    Items[Items.Count-1].Checked := True;
    PlotBar.Max := 60 * 60 * (1 + 5 * Items.Count); // 1 hr + 5/act
    PlotBar.Hint := 'Cutscene omitted';
    with Items.Add do begin
      Caption := 'Act ' + IntToRoman(Items.Count-1);
      MakeVisible(false);
      Checked := False;
      Width := Width-1;
    end;
  end;
  WinItem;
  WinEquip;
  SaveGame;
end;


{$IFDEF LOGGING}
procedure TMainForm.Log(line: String);
var
  stamp: String;
  logname: String;
  log: Text;
begin
  if FLogEvents then begin
    logname := ChangeFileExt(GameSaveName, '.log');
    DateTimeToString(stamp, '[yyyy-mm-dd hh:nn:ss]', Now);
    AssignFile(log, logname);
    if FileExists(logname) then Append(log) else Rewrite(log);
    WriteLn(log, stamp + ' ' + line);
    Flush(log);
    CloseFile(log);
  end;
end;
{$ENDIF}

procedure TMainForm.ExportCharSheet;
var
  f: TextFile;
begin
  AssignFile(f, ChangeFileExt(GameSaveName, '.sheet'));
  Rewrite(f);
  Write(f, CharSheet);
  Flush(f);
  CloseFile(f);
end;

function TMainForm.CharSheet: String;
var
  i: Integer;
  f: String;
  procedure Wr(a: String); begin f := f + a; end;
  procedure WrLn(a: String); overload; begin Wr(a + #13#10); end;
  procedure WrLn; overload; begin Wr(#13#10); end;
begin
  Wr(Get(Traits,'Name'));
  WrLn;
  WrLn(Get(Traits,'Race') + ' ' +  Get(Traits,'Class'));
  WrLn(Format('Level %d (exp. %d/%d)', [GetI(Traits,'Level'), ExpBar.Position, ExpBar.Max]));
  //WrLn('Level ' + Get(Traits,'Level') + ' (' + ExpBar.Hint + ')');
  WrLn;
  with Plots do if Items.Count > 0 then
    WrLn('Plot stage: ' + Items[Items.Count-1].Caption + ' (' + PlotBar.Hint + ')');
  with Quests do if Items.Count > 0 then
    WrLn('Quest: ' + Items[Items.Count-1].Caption + ' (' + QuestBar.Hint + ')');
  WrLn;
  WrLn( 'Stats:');
  WrLn( Format('  STR%7d', [GetI(Stats,'STR')]));
  WrLn( Format('  CON%7d', [GetI(Stats,'CON')]));
  WrLn( Format('  DEX%7d', [GetI(Stats,'DEX')]));
  WrLn( Format('  INT%7d', [GetI(Stats,'INT')]));
  WrLn( Format('  WIS%7d      HP Max%7d', [GetI(Stats,'WIS'), GetI(Stats,'HP Max')]));
  WrLn( Format('  CHA%7d      MP Max%7d', [GetI(Stats,'CHA'), GetI(Stats,'MP Max')]));
  WrLn;
  WrLn( 'Equipment:');
  for i := 1 to Equips.Items.Count-1 do
    if Get(Equips,i) <> '' then
      WrLn( '  ' + LeftStr(Equips.Items[i].Caption + '            ', 12) + Get(Equips,i));
  WrLn;
  WrLn( 'Spell Book:');
  with Spells do
    for i := 1 to Items.Count-1 do
      WrLn( '  ' + Items[i].Caption + ' ' + Get(Spells,i));
  WrLn;
  WrLn( 'Inventory (' + EncumBar.Hint + '):');
  WrLn( '  ' + Indefinite('gold piece', GetI(Inventory, 'Gold')));
  with Inventory do
    for i := 2 to Items.Count-1 do
      if Pos(' of ', Items[i].Caption) > 0
      then WrLn( '  ' + Definite(Items[i].Caption, GetI(Inventory,i)))
      else WrLn( '  ' + Indefinite(Items[i].Caption, GetI(Inventory,i)));
  WrLn;
  WrLn( '-- ' + DateTimeToStr(Now));
  WrLn( '-- Progress Quest 6.2 - http://progressquest.com/');
  Result := f;
end;

procedure TMainForm.Task(caption: String; msec: Integer);
begin
  Kill.SimpleText := caption + '...';
  {$IFDEF LOGGING}
  Log(Kill.SimpleText);
  {$ENDIF}
  with TaskBar do begin
    Position := 0;
    Max := msec;
  end;
end;

procedure TMainForm.Add(list: TListView; key: String; value: Integer);
var line: String;
begin
  Put(list, key, value + GetI(list,key));
  if value = 0 then Exit;

  if value > 0 then line := 'Gained' else line := 'Lost';
  if key = 'Gold' then begin
    key := 'gold piece';
    if value > 0 then line := 'Got paid' else line := 'Spent';
  end;
  if value < 0 then value := -value;
  line := line + ' ' + Indefinite(key, value);
  {$IFDEF LOGGING}
  Log(line);
  {$ENDIF}
end;

procedure TMainForm.AddR(list: TListView; key: String; value: Integer);
begin
  Put(list, key, IntToRoman(value + RomanToInt(Get(list,key))));
end;

function TMainForm.Get(list: TListView; key: String): String;
begin
  Result := Get(list, IndexOf(list,key));
end;

function TMainForm.Get(list: TListView; index: Integer): String;
begin
  with list.Items.Item[index] do begin
    if SubItems.Count < 1
    then Result := ''
    else Result := SubItems[0];
  end;
end;

function TMainForm.GetI(list: TListView; key: String): Integer;
begin
  Result := StrToIntDef(Get(list,key),0);
end;

function TMainForm.GetI(list: TListView; index: Integer): Integer;
begin
  Result := StrToIntDef(Get(list,index),0);
end;

function TMainForm.Sum(list: TListView): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to list.Items.Count - 1 do
    Inc(Result, GetI(list,i));
end;

procedure PutLast(list: TListView; value: String);
begin
  if list.Items.Count > 0 then
  with list.Items.Item[list.Items.Count-1] do begin
    if SubItems.Count < 1
    then SubItems.Add(value)
    else SubItems[0] := value;
  end;
  list.Width := list.Width - 1; // trigger an autosize
end;

procedure TMainForm.LevelUp;
var
  i: Integer;
begin
  Add(Traits,'Level',1);
  Add(Stats,'HP Max', GetI(Stats,'CON') div 3 + 1 + Random(4));
  Add(Stats,'MP Max', GetI(Stats,'INT') div 3 + 1 + Random(4));
  for i := 1 to 2 do WinStat;
  WinSpell;
  with ExpBar do begin
    Position := 0;
    Max := LevelUpTime(GetI(Traits,'Level'));
  end;
  SaveGame;
end;

procedure TMainForm.ClearAllSelections;
begin
      Equips.ClearSelection;
      Spells.ClearSelection;
      Stats.ClearSelection;
      Traits.ClearSelection;
      Inventory.ClearSelection;
      Plots.ClearSelection;
      Quests.ClearSelection;
end;

function RoughTime(s: Integer): String;
begin
  if s < 120 then Result := IntToStr(s) + ' seconds'
  else if s < 60 * 120 then Result := IntToStr(s div 60) + ' minutes'
  else if s < 60 * 60 * 48 then Result := IntToStr(s div 3600) + ' hours'
  else Result := IntToStr(s div (3600 * 24)) + ' days';
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
var
  gain: Boolean;
  elapsed: Integer;
begin
  gain := Pos('kill|',fTask.Caption) = 1;
  with TaskBar do begin
    if Position >= Max then begin
      ClearAllSelections;

      if Kill.SimpleText = 'Loading....' then Max := 0;

      // gain XP / level up
      if gain then with ExpBar do if Position >= Max
      then LevelUp
      else Position := Position + TaskBar.Max div 1000;
      with ExpBar do Hint := IntToStr(Max-Position) + ' XP needed for next level';

      // advance quest
      if gain then if Plots.Items.Count > 1 then with QuestBar do if Position >= Max then begin
          CompleteQuest;
      end else if Quests.Items.Count > 0 then begin
          Position := Position + TaskBar.Max div 1000;
          Hint := IntToStr(100 * Position div Max) + '% complete';
      end;

      // advance plot
      if gain then with PlotBar do if Position >= Max
      then InterplotCinematic
      else Position := Position + TaskBar.Max div 1000;

      //Time.Caption := FormatDateTime('h:mm:ss',PlotBar.Position / (24.0 * 60 * 60));
      PlotBar.Hint := RoughTime(PlotBar.Max-PlotBar.Position) + ' remaining';
      //PlotBar.Hint := FormatDateTime('h:mm:ss" remaining"',(PlotBar.Max-PlotBar.Position) / (24.0 * 60 * 60));

      Dequeue();
    end else with TaskBar do begin
      elapsed := LongInt(gettickcount64) - LongInt(Timer1.Tag);
      if elapsed > 100 then elapsed := 100;
      if elapsed < 0 then elapsed := 0;
      Position := Position + elapsed;
    end;
  end;
  Timer1.Tag := gettickcount64;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  QuestBar.Position := 0;
  PlotBar.Position := 0;
  TaskBar.Position := 0;
  ExpBar.Position := 0;
  Encumbar.Position := 0;

  FReportSave := true;
  FLogEvents := false;
  FMakeBackups := true;
  FExportSheets := false;

  { Fix a macOS bundle issue }
  WorkDir := '.';
  if GetCurrentDir = '/' then begin
     ShowMessage('You have to choose a working directory to store save files.');
     with TSelectDirectoryDialog.Create(nil) do
       try
          if Execute then
             WorkDir := FileName;
       finally
       end;
  end;
end;

function TMainForm.RollCharacter: Boolean;
var
  f: Integer;
begin
  Result := true;
  repeat
    if not NewGuyForm.Go then begin
      Result := false;
      Exit;
    end;
    Put(Traits, 'Name', NewGuyForm.Name.Text);
    if FileExists(GameSaveName) and
          (mrNo = MessageDlg('The saved game "' + GameSaveName + '" already exists. Do you want to overwrite it?', mtWarning, [mbYes,mbNo], 0)) then begin
      // go around again
    end else begin
      f := FileCreate(GameSaveName);
      if f = -1 then begin
        ShowMessage('The thought police don''t like the name "' + GameSaveName + '". Choose a name without \\ / : * ? " < > or | in it.');
      end else begin
        FileClose(f);
        Break;
      end;
    end;
  until false;

  with NewGuyForm do begin
    Put(Traits,'Name',Name.Text);
    Put(Traits,'Race',Race.Items[Race.ItemIndex]);
    Put(Traits,'Class',Klass.Items[Klass.ItemIndex]);
    Put(Traits,'Level',1);
    Put(Stats,'STR',STR.Tag);
    Put(Stats,'CON',CON.Tag);
    Put(Stats,'DEX',DEX.Tag);
    Put(Stats,'INT',INT.Tag);
    Put(Stats,'WIS',WIS.Tag);
    Put(Stats,'CHA',CHA.Tag);
    Put(Stats,'HP Max',Random(8) + CON.Tag div 6);
    Put(Stats,'MP Max',Random(8) + INT.Tag div 6);
    Put(Equips,'Weapon','Sharp Stick');
    Put(Inventory,'Gold',0);
    InventoryLabelAlsoGameStyle.Tag := 3;//GameStyle.Position;
    ClearAllSelections;
    GoButtonClick(NewGuyForm);
  end;
end;

const
  KUsage =
    'Usage: pq [flags] [game.pq3]'#10 +
    #10 +
    'Flags:'#10 +
    '  -no-backup     Do not make a backup file when saving the game'#10 +
    {$IFDEF LOGGING}
    '  -log           Create a text log of events as they occur in the game'#10 +
    {$ENDIF}
    '  -no-report-save   Do not display the "Game saved" message when saving'#10 +
    '  -export        Export a text character sheet periodically'#10 +
    '  -export-only   Export a text character sheet now, then exit'#10 +
    '  -help          Display this chatter (and exit)'#10 ;

procedure TMainForm.FormShow(Sender: TObject);
var
  done, exportandexit: Boolean;
  i: Integer;
begin
  if Timer1.Enabled then Exit;
  done := false;
  exportandexit := false;
  for i := 1 to ParamCount do begin
    if ParamStr(i) = '-backup'
    then FMakeBackups := true
    {$IFDEF LOGGING}
    else if ParamStr(i) = '-log'
    then FLogEvents := true
    {$ENDIF}
    else if ParamStr(i) = '-no-report-save'
    then FReportSave := false
    else if ParamStr(i) = '-export'
    then FExportSheets := true
    else if ParamStr(i) = '-export-only'
    then exportandexit := true
    else if ParamStr(i) = '-help'
    then begin
      ShowMessage(KUsage);
      Close;
      Exit;
    end else begin
      LoadGame(ParamStr(i));
      if exportandexit then begin
        ExportCharSheet;
        Timer1.Enabled := false;
        Close;
      end;
      Exit;
    end;
  end;
  while not Done do begin
    case FrontForm.ShowModal of
    mrOk: begin
        done := RollCharacter;
      end;
    mrRetry: begin
      // load
        if FrontForm.OpenDialog1.Execute then begin
          LoadGame(FrontForm.OpenDialog1.Filename);
          Done := true;
        end;
      end;
    mrCancel: begin
        Close;
        Done := true;
      end;
    end;
  end;
end;

function TMainForm.SaveGame: Boolean;
var
  f: TFileStream;
  m: TMemoryStream;
  i: Integer;
begin
  {$IFDEF LOGGING}
  Log('Saving game: ' + GameSaveName);
  {$ENDIF}
  Result := true;

  try
    if FMakeBackups then begin
      DeleteFile(ChangeFileExt(GameSaveName, '.bak'));
      RenameFile(PChar(GameSaveName), PChar(ChangeFileExt(GameSaveName, '.bak')));
    end;
    f := TFileStream.Create(GameSaveName, fmCreate);
  except
    on EfCreateError do begin
      Result := false;
      Exit;
    end;
  end;


  //ClearAllSelections;
  m := TMemoryStream.Create;
  for i := 0 to ComponentCount-1 do
    m.WriteComponent(Components[i]);
  m.WriteComponent(MainForm);
  m.Seek(0, soFromBeginning);
  //ZCompressStream(m, f);
  f.Write(m, m.Size);
  m.Free;
  f.Free;
end;

procedure TMainForm.LoadGame(name: String);
var
  f: TStream;
  m: TStream;
  i: Integer;
begin
  FSaveFileName := name;
  m := TMemoryStream.Create;
  f := TFileStream.Create(name, fmOpenRead);
  try
    //ZDecompressStream(f, m);
    m.Write(f, f.Size);
    f.Free;
  except

  end;
  Traits.Items.Clear;
  Stats.Items.Clear;
  Equips.Items.Clear;
  m.Seek(0, soFromBeginning);
  for i := 0 to ComponentCount-1 do
    m.ReadComponent(Components[i]);
  m.Free;
  {$IFDEF LOGGING}
  Log('Loaded game: ' + name);
  {$ENDIF}
  StartTimer;
  TriggerAutosizes;
end;

procedure TMainForm.TriggerAutosizes;
begin
  Plots.Width := 100;
  Quests.Width := 100;
  Inventory.Width := 100;
  Equips.Width := 100;
  Spells.Width := 100;
  Traits.Width := 100;
  Stats.Width := 100;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Timer1.Enabled then begin
    Timer1.Enabled := false;
    if SaveGame then
      if FReportSave then
        ShowMessage('Game saved as ' + GameSaveName);
  end;
  FReportSave := true;
  Action := caFree;
end;

function TMainForm.GameSaveName: String;
begin
  if FSaveFileName = '' then begin
    FSaveFileName := Get(Traits,'Name');
    FSaveFileName := FSaveFileName + kFileExt;
    FSaveFileName := ExpandFileName(PChar(WorkDir + PathDelim + FSaveFileName));
  end;
  Result := FSaveFileName;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = ord('A')) then begin
    ShowMessage(CharSheet);
  end;
end;

initialization
  RegisterClasses([TMainForm]);
end.

