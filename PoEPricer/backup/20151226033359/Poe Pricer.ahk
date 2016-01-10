
;
; AutoHotkey Version: 1.x
; Language:       English
; Platform:       Win9x/NT
; Author:         A.N.Other <myemail@nowhere.com>
;
; Script Function:
;	Template script (you can customize this template by editing "ShellNew\Template.ahk" in your Windows folder)
;

;#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, Force
#Include %A_ScriptDir%\Data\ToolTipEx.ahk

#MaxThreadsPerHotkey 1
;#MaxThreads 2


#IfWinActive,  ahk_exe PathOfExile.exe



menu, tray, Icon, %A_ScriptDir%\Data\PoePricer.ico

Global prefixes, suffixes, implicit, affixes
Global TT, TT_Affixes
Global TT_Result, TT_ResultExt

Global BaseBoots, BaseGloves, BaseWeapons, BaseHelmets, BaseBodyArmours, BaseSpiritShields
Global Item, Filter_Boots, Filter_Gloves, Filter_Helmets, Filter_BodyArmours, Filter_Belts, Filter_Amulets, Filter_Rings, Filter_Quivers, Filter_Spirit_Shields, Filter_1h_spell, Filter_WeaponDPS, Filter_2h_skill
Global CounterBefore, CounterAfter
Global f_ShowScore := False
Global f_AutoScan := True
Global f_ToolTip := False
Global path_FilterFolder := "Filter"
Global ScanToggle := False
Global SingleScanToggle := False

Global X, Y
Global t_clip


IniRead, f_AutoScan, PoePricer.ini, Flags, opt_AutoScan, 0
IniRead, f_ShowScore, PoePricer.ini, Flags, opt_ShowScore, 0
IniRead, path_FilterFolder, PoePricer.ini, Path, opt_FilterFolder, "Filter"

;f_ShowScore := True


; считывание префиксов/суффиксов/имплисит в регексп виде
FileRead, prefixes, %A_ScriptDir%\Data\Affixes\prefixes.txt
FileRead, suffixes, %A_ScriptDir%\Data\Affixes\suffixes.txt
FileRead, implicit, %A_ScriptDir%\Data\Affixes\implicit.txt
FileRead, affixes, %A_ScriptDir%\Data\Affixes\affixes.txt

SetFormat, Float, 0.2
;считывание прототипов доспеxов

Global BaseHelmets:= new BaseArmours_("Helmets")
Global BaseBodyArmours := new BaseArmours_("BodyArmour")
Global BaseWeapons := new BaseWeapons_("Weapon")
Global BaseBoots := new BaseArmours_("Boots")
Global BaseGloves := new BaseArmours_("Gloves")
Global BaseSpiritShields := new BaseArmours_("SpiritShields")

;массивы с таблицей тиров для аффиксов
Global Affix_ComboPhys := new ComboAffixBracket_("ComboLocalPhysAcc")
Global Affix_Acc := new AffixBracket_("AccuracyRating")
Global Affix_Phys := new AffixBracket_("LocalPhys")
Global Affix_SP := new AffixBracket_("SpellDamage")
Global Affix_ComboSP := new ComboAffixBracket_("ComboSpellMana")
Global Affix_SP_Staff := new AffixBracket_("StaffSpellDamage")
Global Affix_ComboSP_Staff := new ComboAffixBracket_("StaffComboSpellMana")
Global Affix_Mana := new AffixBracket_("MaxMana")
Global Affix_ComboArmourStun := new ComboAffixBracket_("ComboArmourStun")
Global Affix_StunRecovery := new AffixBracket_("StunRecovery")
Global Affix_Armour := new AffixBracket_("Armour")

Global Filter_Boots := new Filter_("Boots")
Global Filter_Gloves := new Filter_("Gloves")
Global Filter_Helmets := new Filter_("Helmets")
Global Filter_BodyArmours := new Filter_("BodyArmours")
Global Filter_Belts := new Filter_("Belts")
Global Filter_Amulets := new Filter_("Amulets")
Global Filter_Rings := new Filter_("Rings")
Global Filter_Quivers := new Filter_("Quivers")
Global Filter_1h_spell := new Filter_("1h_spell")
Global Filter_Spirit_Shields := new Filter_("Spirit_Shields")
Global Filter_2h_skill := new Filter_("2h_skill")
Global Filter_WeaponDPS := new WeaponFilter_("WeaponDPS")




;control hotkey
~vkA2::
{
	clip_saved := Clipboard
	clip_parsed := Clipboard
	
	
	MouseGetPos, X, Y
	
	While (GetKeyState("LControl", "P") == 1)
	{
		IfWinNotActive,  ahk_exe PathOfExile.exe
		{
			goto, ScanEnd
		}
		
		MouseGetPos, CurrX, CurrY
		MouseMoved := (CurrX - X) ** 2 + (CurrY - Y) ** 2 > 60 ** 2
		If (MouseMoved)
			ToolTipEx()
		
		If (GetKeyState("C", "P") == 1)
		{
			sleep, 10
			If (SubStr(Clipboard,StrLen(Clipboard), 1 ) == " ")
				clip_saved := Clipboard
			else
				clip_saved := Clipboard . A_Space
			goto, Scanend
		}
		
		DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
		Send, ^{VK43}
		Loop, 10
		{
			If (GetKeyState("C", "P") == 1)
			{
				sleep, 10
				If (SubStr(Clipboard,StrLen(Clipboard), 1 ) == " ")
					clip_saved := Clipboard
				else
					clip_saved := Clipboard . A_Space
				goto, Scanend
			}
			
			If (Clipboard <> clip_parsed) and Clipboard
			{
				clip_parsed := Clipboard
				ParseItemData(Clipboard)
				MouseGetPos, X, Y
				ShowToolTip()
				break
			}
			sleep, 1
		}
	}
	sleep, 10
	
	ScanEnd:
	ToolTipEx()
	Clipboard := clip_saved
}
return

#F9::
Reload
return




ShowToolTip()
{
	If (f_ShowScore == 1)
		t_string := TT_ResultExt
	else
		t_string := TT_Result
	
	If (Item.Success)
	{
		ToolTipEx(t_string,X-40 ,Y+70 , ,, "yellow", "black")
	}
	else 
	{
		If (Item.Unidentified)
			ToolTipEx(t_string, X-40, Y+70,,,"yellow","black")
		else
			ToolTipEx(t_string, X-40, Y+70,,,"white","black")
	}
}
return

GuiClose:
ExitApp
return






class Item_ {
	Name := ""
	BaseType :=""
	ClassType := ""
	GripType := ""
	Implicit := ""
	iLevel := 0
	Unidentified := False
	
	Affixes := 0
	Suffixes := 0
	Prefixes := 0
	SPAffixes := 0
	
	PhysDPS := 0
	CraftPhysDPS := 0
	MultiPhysDPS := 0
	
	ElemDPS := 0
	CraftElemDPS := 0
	MultiElemDPS := 0
	FlatElem := 0
	
	
	TotalSpellDPS := 0
	ElemSpellDPS := 0
	FlatSpellDPS := 0
	
	AR := 0
	ES := 0
	EV := 0
	CraftAR := 0
	CraftES := 0 
	CraftEV := 0
	MultiAR := 0
	MultiES := 0
	MultiEV := 0
	
	CraftMaxLife := 0
	
	RessistanceAffixes := 0
	ElemDamageAffixes := 0
	
	BaseAR := 0
	BaseEV := 0
	BaseES := 0
	
	
	BaseDamage := [0,0]
	APS := 0
	BaseCrit := 0
	CraftedAPS := 0
	WeaponCrit := 0
	CraftWeaponCrit := 0
	CraftTotalSpellDamage := 0
	Links := 0
	
	FlatAR := 0
	FlatES := 0
	FlatEV := 0
	LocalArmour := 0
	MaxLife := 0
	FlatPhysDamage := 0
	LocalPhys := 0
	LifeLeech := 0
	ManaLeech := 0
	MoveSpeed := 0
	Block := 0
	BlockRecovery := 0
	WED := 0
	FlatFire := 0
	FlatCold := 0
	FlatLightning := 0
	FlatChaos := 0
	FlatSpellCold := 0
	FlatSpellFire := 0
	FlatSpellLightning := 0
	SpellDamage := 0
	
	ItemRarity := 0
	StunRecovery := 0
	Accuracy := 0
	LocalAccuracyRating := 0
	MaxMana := 0
	DOT := 0
	
	TotalRes := 0
	AllRes := 0
	Int := 0
	Str := 0
	Dex := 0
	ColdRes := 0
	FireRes := 0
	LightningRes := 0
	ChaosRes := 0
	LightRadius := 0
	LifeOnKill := 0
	ManaOnKill := 0
	IAS := 0
	CastSpeed := 0
	AddBlockChance := 0
	StunTreshold := 0
	LocalColdDamage := 0
	LocalLightningDamage := 0
	LocalFireDamage := 0
	ProjSpeed := 0	
	Crit := 0
	CritDamage := 0
	GlobalCrit := 0
	SpellCrit := 0
	BowGem := 0
	FireGem := 0
	ColdGem := 0
	LightningGem := 0
	LevelGem := 0
	MinionGem := 0
	MeleeGem := 0
	ChaosGem := 0
	LocalElem := 0
	
	; Flags for affixes
	
	IsFlatAR := False
	IsFlatES := False
	IsFlatEV := False
	IsLocalArmour := False
	IsMaxLife := False
	IsFlatPhysDamage:= False
	IsLocalPhys := False
	IsLifeLeech := False
	IsManaLeech := False
	IsMoveSpeed := False
	IsBlock := False
	IsBlockRecovery := False
	IsWED := False
	IsFlatFire:= False
	IsFlatCold:= False
	IsFlatLightning:= False
	IsFlatChaos:= False
	IsFlatSpellCold:= False
	IsFlatSpellFire:= False
	IsFlatSpellLightning:= False
	IsSpellDamage := False
	IsBowGem := False
	IsFireGem := False
	IsColdGem := False
	IsLightningGem := False
	IsLevelGem := False
	IsMinionGem := False
	IsMeleeGem := False
	IsChaosGem := False
	
	IsItemRarity := False
	IsStunRecovery := False
	IsAccuracyRating := False
	IsLocalAccuracyRating := False
	IsMaxMana := False
	
	IsDOT := False
	IsInt := False
	IsStr := False
	IsDex := False
	IsColdRes := False
	IsFireRes := False
	IsLightningRes := False
	IsChaosRes := False
	IsLightRadius := False
	IsLifeOnKill := False
	IsManaOnKill := False
	IsIAS := False
	IsCastSpeed := False
	IsAddBlockChance := False
	IsStunTreshold := False
	IsLocalColdDamage := False
	IsLocalLightningDamage := False
	IsLocalFireDamage := False
	IsProjSpeed := False
	IsCrit := False
	IsCritDamage := False
	IsGlobalCrit := False
	IsSpellCrit := False
	
	IsLocalElem := False
	IsAllRes := False
	IsAllStat := False
	; need for crafting
	IsTotalRes := False
	
	;flags for combo affixes
	IsLocalPhysAff := False
	IsSpellDamageAff := False
	IsMaxManaAff := False
	IsAccuracyAff := False
	IsLocalArmourAff := False
	
	;flags for class
	HasImplicit := False	
	IsCorrupted := False
	IsWeapon := False
	IsQuiver := False
	IsUnidentified := False
	IsBelt := False
	IsRing := False
	IsBow := False
	IsAmulet := False
	IsTalisman := False
	IsBoots := false
	IsBodyArmour := false
	IsHelm := false
	IsGloves := false	
	IsJewel := False
	IsMap := False
	IsMirrored := False
	HasEffect := False
	
	Success := False
	
	
	Get(var)
	{
		Return this[var]
	}
	
	
	AddValue(var, value, var2, value2, var3, value3, var4, value4)
	{
		If var
			this[var] += value
		If var2
			this[var2] += value2
		If var3
			this[var3] += value3
		If var4
			this[var4] += value4
	}
	
	AddValueImplicit(var, value, var2, value2, var3, value3, var4, value4)
	{
		If value2
		{
			If var
				this[var] += value
			If var2
				this[var2] += value2
			If var3
				this[var3] += value3
			If var4
				this[var4] += value4
			return
		}
		If var
			this[var] += value
		If var2
			this[var2] += value
		If var3
			this[var3] += value
		If var4
			this[var4] += value
	}
}




Class Filter_ {
	Params := []
	ValueLo := []
	ValueHi := []
	ValueCraft := []
	Weight := []
	ValueTarget := []
	ScoreHits4 := 0
	ScoreHits5 := 0
	GripType := False
	Score := 0
	AffixType := []
	
	
	__New(FileName) {
		FileRead, t_text, %A_ScriptDir%\Data\%path_FilterFolder%\%FileName%.txt
		Loop, Parse, t_text, `n, `r
		{
			If ((SubStr(A_LoopField,1,1) == ";") or (RegExMatch(A_LoopField,"^$")))
				Continue
			If (SubStr(A_LoopField,1,1) == "!")
			{
				t_line := StrReplace(A_LoopField, "!", ,1)
				StringSplit, t_string, t_line, `t
				this[t_string1] := t_string2
				Continue
			}
			t_string1 :=
			t_string2 :=
			t_string3 :=
			t_string4 :=
			t_string5 :=
			t_string6 :=
			t_string7 :=
			t_string8 :=
			StringSplit, t_string, A_LoopField, `t
			this.Params.Insert(t_string1)
			this.ValueLo.Insert(t_string2)
			this.ValueHi.Insert(t_string3)
			this.ValueCraft.Insert(t_string4)
			this.AffixType.Insert(t_string5)
			this.Weight.Insert(t_string6)
			this.ValueTarget.Insert(t_string7)
		}
	}
	
	Scoring()
	{
		PadWords := "(ChaosRes|FlatSpellFire|LightningRes|ItemRarity|SpellDamage|MoveSpeed|LocalPhys|FlatPhysDamage|GlobalCrit|CritDamage|CastSpeed|LocalElem|TotalRes|FlatElem)"
		PadWords2 := "(CraftTotalSpellDamage|FlatSpellLightning)"
		
		
		If (	Item.ClassType <> this.ClassType)
			If (Item.GripType <> this.GripType)
				return False
		
		
		t_ESFlag := False
		t_craftFlag := False
		t_totalRes := 0
		t_Score := 0	
		t_Value := 0
		ActualScore := 0
		FilterHits := 0
		
		
		
		For i, element in this.Params
		{
			t_craft := False
			pad := "			"
			If (RegExMatch(element,PadWords))
				pad := "		"
			If (RegExMatch(element,PadWords2))
				pad := "	"
			
			t_value := Item.Get(element)
			
			If (element == "AR") or (element == "ES") or (element == "EV")
			{
				t_var := Craft . element
				
				If (Item.Get(t_var) > this.ValueTarget[i]) and (t_CraftFlag == False)
				{
					
					t_value := Item.Get(t_var)
					t_Score := this.Weight[i]*((t_value - this.ValueLo[i])/(this.ValueHi[i] - this.ValueLo[i]))*100
					ActualScore += t_Score
					
					;msgbox, %  Item.Get(element)  "-" Item.Get(t_var) "-" Item.ES "-" var
					If (Item.Get(element) < Item.Get(t_var))
					{
						t_armour_string := "	[CRAFT]"
						t_CraftFlag := True
					}
					else
						t_armour_string := ""
					TT_Result := TT_Result . "`n" . element . ":" . pad . Round(t_value) . t_armour_string
					TT_ResultExt := TT_ResultExt . "`n" . element . ":" . pad . Round(t_value) . "  [" . Round(t_Score) . "]" . t_armour_string
					FilterHits++
					continue
				}
				
			}
			
			
			IsVar := "Is" . element
			;msgbox, % element " CraftFlag: "t_CraftFlag " AffixType: " Item.Get(this.AffixType[i]) " FlagAffix: " Item.Get(IsVar) " CraftValue: " (this.ValueCraft[i]) " Corrupt: " Item.IsCorrupted 
			If ((t_CraftFlag == False) and (Item.Get(this.AffixType[i]) < 3) and (Item.Get(IsVar) == False) and ((this.ValueCraft[i]) > 0) and (Item.IsCorrupted == False))
			{
				If ((element == "CastSpeed") and (Item.ClassType == "Dagger"))
					continue
				
				t_value := Item.Get(element) + this.ValueCraft[i]
				FilterHits++
				t_craftFlag := True
				t_craft := True
				
				
			}
			
			
			
			If (t_value >= this.ValueTarget[i])
			{
				If (element == "TotalRes")
				{
					If (Item.ColdRes > 20)
						FilterHits++
					If (Item.FireRes > 20)
						FilterHits++
					If (Item.LightningRes > 20)
						FilterHits++
					If (Item.ChaosRes > 13)
						FilterHits++
					If (Item.AllRes > 8)
						FilterHits++
					FilterHits--
				}
				
				
				If (element == "CraftTotalSpellDamage") and (Item.CraftTotalSpellDamage > Item.SpellDamage)
					t_CraftFlag := True
				
				
				If (Value > 20)
					Value := Round(Value)
				t_Score := this.Weight[i]*((t_value - this.ValueLo[i])/(this.ValueHi[i] - this.ValueLo[i]))*100
				ActualScore += t_Score
				If t_craft
				{
					TT_Result := TT_Result . "`n" . element . ":" . pad . Round(t_value) . "  [CRAFT]"	
					TT_ResultExt := TT_ResultExt . "`n" . element . ":" . pad . Round(t_value) . "  [" . Round(t_Score) . "]  [CRAFT]"
				}
				else
				{
					TT_Result := TT_Result . "`n" . element . ":" . pad . Round(t_value)
					TT_ResultExt := TT_ResultExt . "`n" . element . ":" . pad . Round(t_value) . "  [" . Round(t_Score) . "]"
				}
				;msgbox, % element "-" t_value "-" this.ValueTarget[i] t_Score
				FilterHits++
			}
		}
		
		TT_Result := TT_Result .  "`n--------------------------------------"
		TT_ResultExt := TT_ResultExt .  "`n--------------------------------------"
		
		TT_Result := "`n--------------------------------------`nHits:	" . FilterHits . "	Score:	" . Round(ActualScore) . "`n--------------------------------------" . TT_Result
		TT_ResultExt := "`n--------------------------------------`nHits:	" . FilterHits . "	Score:	" . Round(ActualScore) . "`n--------------------------------------" . TT_ResultExt
		
		If (ActualScore >= this.Score)
		{
			Item.Success := True
			return True
		}
		If (ActualScore >= this.ScoreHits4) and (FilterHits >= 4)
		{
			Item.Success := True
			return True
		}
		If (ActualScore >= this.ScoreHits5) and (FilterHits >= 5)
		{
			Item.Success := True
			return True
		}
		
		return False
	}
}


Class WeaponFilter_ {
	ClassType := []
	PhysDPS := []
	ElemDPS := []
	Gems := []
	
	__New(FileName) {
		FileRead, t_text, %A_ScriptDir%\Data\Filter\%FileName%.txt
		Loop, Parse, t_text, `n, `r
		{
			If ((SubStr(A_LoopField,1,1) == ";") or (RegExMatch(A_LoopField,"^$")))
				Continue
			If (StrLen(A_LoopField) < 3)
			{
				Continue
			}
			If (SubStr(A_LoopField,1,1) == "!")
			{
				t_line := StrReplace(A_LoopField, "!", ,1)
				StringSplit, t_string, t_line, `t
				this[t_string1] := t_string2
				Continue
			}
			t_string1 :=
			t_string2 :=
			t_string3 :=
			t_string4 :=
			t_string5 :=
			t_string6 :=
			t_string7 :=
			t_string8 :=
			StringSplit, t_string, A_LoopField, `t
			this.ClassType.Insert(t_string1)
			this.PhysDPS.Insert(t_string2)
			this.ElemDPS.Insert(t_string3)
			this.Gems.Insert(t_string4)
		}
	}
	
	
	Scoring(t_ClassType)
	{
		For i, element in this.ClassType
		{
			t_CraftFlag := False
			If (t_ClassType == element)
			{
				
				If (this.PhysDPS[i])
				{
					TT_PhysDPS := "`nPhysDPS:	"
					If (Item.CraftPhysDPS > this.PhysDPS[i])
					{
						If Item.CraftPhysDPS > Item.PhysDPS
						{
							TT_PhysDPS := TT_PhysDPS . Item.CraftPhysDPS . "  [CRAFT]"
							t_CraftFlag := True
						}
						Item.Success := True
					}
					else
					{
						TT_PhysDPS := TT_PhysDPS . Item.PhysDPS
					}
				}
				
				TT_ElemDPS := Item.ElemDPS
				
				If (this.ElemDPS[i])
				{
					TT_ElemDPS := "`nElemDPS:	"
					If (Item.CraftElemDPS > this.ElemDPS[i]) and (t_CraftFlag == False)
					{
						If Item.CraftElemDPS > Item.ElemDPS
						{
							TT_ElemDPS := TT_ElemDPS . Item.CraftElemDPS . "  [CRAFT]"
							t_CraftFlag := True
						}
						Item.Success := True
					}
					else
					{
						TT_ElemDPS := TT_ElemDPS . Item.ElemDPS
					}
				}
				
				
				If (this.CraftWeaponCrit[i])
				{
					TT_Crit := "`nCrit:		"
					If (Item.CraftWeaponCrit > this.WeaponCrit[i]) and (t_CraftFlag == False)
					{
						If Item.CraftWeaponCrit > Item.WeaponCrit
						{
							TT_Crit := TT_Crit . Item.CraftWeaponCrit . "%  [CRAFT]"
							t_CraftFlag := True
						}
						;Item.Success := True
					}
					else
					{
						TT_Crit := TT_Crit . Item.WeaponCrit
					}
				}
				
				t_Gems := Item.ColdGem + Item.FireGem + Item.LevelGem + Item.BowGem + Item.LightningGem + Item.ChaosGem + Item.MeleeGem 
				TT_Gems := t_Gems
				If (this.Gems[i]) 
				{
					If (t_Gems >= this.Gems[i])
					{
						TT_Gems := "`nGems:		" . t_Gems
						Item.Success := True
					}
				}
				
				TT_APS := "`nAttSpeed:	" . Item.CraftedAPS
				
				TT_Result := "`n--------------------------------------" . TT_PhysDPS . TT_ElemDPS . TT_Gems . TT_APS . "`n--------------------------------------"
				TT_ResultExt := TT_Result
				TT_ResultExt := TT_Result
				return 
			}
			
			
		}
		
	}
	
}







Class ComboAffixBracket_ {
	iLevel := []
	ValueLo := []
	ValueHi := []
	Value2Lo := []
	Value2Hi := []
	
	__New(FileName) {
		FileRead, t_text, %A_ScriptDir%\Data\AffixBrackets\%FileName%.txt
		
		Loop, Parse, t_text, `n, `r
		{
			If ((SubStr(A_LoopField,1,1) == ";") or (RegExMatch(A_LoopField,"^$")))
				Continue
			StringSplit, t_bracketline, A_LoopField, `t
			this.iLevel.Insert(t_bracketline1)
			StringSplit, physrange, t_bracketline2, -
			this.ValueLo.Insert(physrange1)
			this.ValueHi.Insert(physrange2)
			StringSplit, accrange, t_bracketline3, -
			this.Value2Lo.Insert(accrange1)
			this.Value2Hi.Insert(accrange2)
			
		}
	}
	
	Value2FromValue(Var, ByRef ValueHi, ByRef ValueLo)
	{
		For i, element in this.iLevel
		{
			If (Var >= this.ValueLo[i] and Var <= this.ValueHi[i])
			{
				ValueLo := this.Value2Lo[i]
				ValueHi := this.Value2Hi[i]
				return True
			}
		}	
		return False
	}
	
	MaxValueFromiLevel(iLevel)
	{
		For i, element in this.iLevel
		{
			If (iLevel < this.iLevel[i])
			{
				value := this.ValueHi[i-1]
				return value
			}
		}	
		value := this.ValueHi[i]
		return value
	}
	
	MaxValue2FromiLevel(iLevel)
	{
		For i, element in this.iLevel
		{
			If (iLevel < this.iLevel[i])
			{
				value := this.Value2Hi[i-1]
				return value
			}
		}	
		value := this.Value2Hi[i]
		return value
	}
	
}

Class AffixBracket_ {
	iLevel := []
	ValueLo := []
	ValueHi := []
	
	__New(FileName) {
		FileRead, t_text, %A_ScriptDir%\Data\AffixBrackets\%FileName%.txt
		Loop, Parse, t_text, `n, `r
		{
			If ((SubStr(A_LoopField,1,1) == ";") or (RegExMatch(A_LoopField,"^$")))
				Continue
			StringSplit, t_bracketline, A_LoopField, `t
			this.iLevel.Insert(t_bracketline1)
			StringSplit, valuerange, t_bracketline2, -
			this.ValueLo.Insert(valuerange1)
			this.ValueHi.Insert(valuerange2)
		}
		
	}
	
	MaxValueFromiLevel(iLevel)
	{
		
		For i, element in this.iLevel
		{
			If (iLevel < this.iLevel[i])
			{
				return this.ValueHi[i-1]
			}
			
		}
		
		return this.ValueHi[i]
	}
	
	MinValueFromiLevel(iLevel)
	{
		For i, element in this.iLevel
		{
			If (iLevel < this.iLevel[i])
			{
				return this.ValueLo[i-1]
			}
		}	
		return this.ValueLo[i]
	}
}

class BaseWeapons_ {
	BaseName := []	
	BaseDamageLo := []
	BaseDamageHi := []
	BaseCC := []
	BaseAPS := []
	
	__New(FileName) {
		FileRead, t_text, %A_ScriptDir%\Data\Bases\%FileName%.txt
		Loop, Parse, t_text, `n, `r
		{
			If ((SubStr(A_LoopField,1,1) == ";") or (RegExMatch(A_LoopField,"^$")))
				Continue
			t_weaponlines1 :=
			t_weaponlines2 :=
			t_weaponlines3 :=
			t_weaponlines4 :=
			t_weaponlines5 :=
			StringSplit, t_weaponlines, A_LoopField, `t
			this.BaseName.Insert(t_weaponlines1)
			this.BaseDamageLo.Insert(t_weaponlines2)
			this.BaseDamageHi.Insert(t_weaponlines3)
			StringReplace, t_weaponlines4, t_weaponlines4, `%,, All
			this.BaseCC.Insert(t_weaponlines4)
			this.BaseAPS.Insert(t_weaponlines5)
		}
	}
	
	SetItem(BaseType, ByRef DamageLo, ByRef DamageHi, ByRef CC, ByRef APS)
	{
		StringReplace, BaseType, BaseType, "ö", "o"
		
		
		
		If (RegExMatch(BaseType, "Maelstr.m Staff"))
			BaseType := "Maelstrom Staff"
		For i, element in this.BaseName
		{
			If (element == BaseType)
			{
				DamageLo += this.BaseDamageLo[i]
				DamageHi += this.BaseDamageHi[i]
				CC += this.BaseCC[i]
				APS += this.BaseAPS[i]
				return True
			}
		}	
	}
}

Class BaseArmours_ {
	BaseName := []	
	BaseAR := []
	BaseES := []
	BaseEV := []
	
	__New(FileName) {
		FileRead, t_text, %A_ScriptDir%\Data\Bases\%FileName%.txt
		Loop, Parse, t_text, `n, `r
		{
			If ((SubStr(A_LoopField,1,1) == ";") or (RegExMatch(A_LoopField,"^$")))
				Continue
			t_lines1 := 0
			t_lines2 := 0
			t_lines3 := 0
			t_lines4 := 0
			StringSplit, t_lines, A_LoopField, `t
			this.BaseName.Insert(t_lines1)	
			this.BaseAR.Insert(t_lines2)
			this.BaseEV.Insert(t_lines3)
			this.BaseES.Insert(t_lines4)
		}
	}
	
	SetItem(BaseType, ByRef AR, ByRef EV, ByRef ES)
	{
		For i, element in this.BaseName
		{
			If (element == BaseType)
			{
				If this.BaseAR[i] > 0
					AR := this.BaseAR[i]
				If this.BaseEV[i] > 0
					EV := this.BaseEV[i]
				If this.BaseES[i] > 0
					ES := this.BaseES[i]
				Return True
			}
			
		}	
		return False
	}
}

IfNotExist, %A_ScriptDir%\data
{
	MsgBox, 16, % Msg.DataDirNotFound
	exit
}

ParseLinks(ItemDataText)
{
	Loop, Parse, ItemDataText, `n, `r
	{
		IfInString, A_LoopField, Sockets
		{
			Sockets:
			
			If (RegExMatch(A_LoopField, ".-.-.-.-.-."))
			{
				Item.Links := 6
				Break
			}
			If (RegExMatch(A_LoopField, ".-.-.-.-."))
			{
				Item.Links := 5
				Break
			}
			If (RegExMatch(A_LoopField, ".-.-.-."))
			{
				Item.Links := 4
				Break
			}
			If (RegExMatch(A_LoopField, ".-.-."))
			{
				Item.Links := 3
				Break
			}
			If (RegExMatch(A_LoopField, ".-."))
			{
				Item.Links := 2
				Break
			}
		}
	}
	return
}



ParseItemData(ItemDataText)
{    
	
	
	Item := new Item_()
	TT_Result := 
	TT_ResultExt := 
	TT_Affixes :=
	TT_PhysDPS :=
	
	TempResult :=
	ItemDataNamePlate :=
	ItemDataLastPart :=
	ItemDataIndexLast := 0
	ItemDataAffixes :=
	ItemDataImplicit :=
	
	
	
	
	
	
    ; AHK only allows splitting on single chars, so first 
    ; replace the split string (\r\n--------\r\n) with AHK's escape char (`)
    ; then do the actual string splitting...
	StringReplace, TempResult, ItemDataText, `r`n--------`r`n, ``, All
	StringSplit, ItemDataParts, TempResult, ``,
	
	ItemDataNamePlate := ItemDataParts1
	ItemDataIndexLast := ItemDataParts0
	ItemDataLastPart := ItemDataParts%ItemDataParts0%
	
	ParseLinks(ItemDataText)
	
	IfNotInString, ItemDataNamePlate, Rarity: Rare
	{
		If (Item.Links > 4)
		{
			TT_Result := "`n`n	Links: " . Item.Links . "		`n`n "
			Item.Success := True
		}
		return False
		;Goto, ParseItemDataEnd
	}
	
	IfInString, ItemDataText, Unidentified
	{
		TT_Result := "`n`n     Unidentified	`n`n "
		Item.Unidentified := True
		return False
	}
	
	IfInString, ItemDataText, Corrupted
	{
		TT := TT . "`n" . "Corrupted"
		Item.IsCorrupted := True
	}
	
	
	
	ItemDataStat := ItemDataParts2
	StringReplace, ItemDataNamePlate, ItemDataText, `r`n, ``, All
	StringSplit,ItemDataNamePlate, ItemDataNamePlate, ``
	Item.Name := ItemDataNamePlate2
	Item.BaseType := ItemDataNamePlate3
	StringReplace, ItemDataStat, ItemDataStat, `r`n, ``, All
	StringSplit, ItemDataStat, ItemDataStat, ``
	ItemStatLine := ItemDataStat1
	;DllCall("QueryPerformanceCounter", "Int64*", CounterStringSplit)
	;DllCall("QueryPerformanceFrequency", "Int64*", Frequency1)
	;перебор прототипов для определения типа предмета
	
	ParseClassType(Item.BaseType, ItemStatLine)
	
	
	
	;DllCall("QueryPerformanceCounter", "Int64*", CounterParseClass)
	;DllCall("QueryPerformanceFrequency", "Int64*", Frequency2)
	
	If (!Item.ClassType)
	{
		
		TT := "Unknown Class"
		;Goto, ParseItemDataEnd
		return False
	}
	If Item.IsMap
	{
		;TT := "Map"
		;Goto, ParseItemDataEnd
		return False
	}
	If Item.IsJewel
	{
		;TT := "Jewel"
		return False
	}
	If Item.IsTalisman
	{
		;TT := "Talisman"
		;Goto, ParseItemDataEnd
		return False
	}
	
	
    ; This function should return the second part of the "Rarity: ..." line
    ; in the case of "Rarity: Unique" it should return "Unique"
	; parse item level
	
	
	Item.IsMirrored := (ItemIsMirrored(ItemDataText))
	Item.HasEffect := (InStr(ItemDataLastPart, "Has"))
	
	
	ItemDataIndexAffixes := ItemDataIndexLast - GetNegativeAffixOffset(Item)
	ItemDataAffixes := ItemDataParts%ItemDataIndexAffixes%
	If (Item.IsRing or Item.IsBelt or Item.IsAmulet or Item.IsQuiver)
	{
		ItemDataImplicit := ItemDataParts4
	} else if ((Item.IsJewel == 0) and (ItemDataIndexAffixes == 7))
	{
		ItemDataImplicit := ItemDataParts6
	}
	
	RegExMatch(ItemDataText,"Item Level: (\d+)\r\n", TempResult)
	Item.iLevel := TempResult1
	
	;msgbox, % ItemDataText  TempResult1
	; парсинг блока с аффиксами и заполнение xарактеристик предмета
	ParseAffixes(ItemDataAffixes)
	
	;DllCall("QueryPerformanceCounter", "Int64*", CounterParseAffix)
	CheckSpellDamageMana()
	CheckPhysAccuracyRating()
	CheckArmourStun()
	CheckItemRarity()
	
	
	; парсинг имплисит блока, обязательно после просчета веса аффиксов (комбоаффиксы и дубли) IR Accuracy\PhysDamage AR\StunRecovery ...
	ParseImplicit(ItemDataImplicit)
	
	
	CalcPhysDPS()
	
	Item.FlatCold /= 2
	Item.FlatFire /= 2
	Item.FlatLightning /= 2
	Item.FlatSpellCold /= 2
	Item.FlatSpellFire /= 2
	Item.FlatSpellLightning /= 2
	Item.FlatChaos /= 2
	Item.FlatPhysDamage /= 2
	
	Item.FlatElem := Item.FlatCold + Item.FlatChaos + Item.FlatFire + Item.FlatLightning
	
	
	
	Item.TotalRes := Item.ChaosRes + Item.FireRes + Item.ColdRes + Item.LightningRes + Item.AllRes*3
	
	
	Item.CraftedAPS := Item.APS + Item.IAS/100
	
	;DllCall("QueryPerformanceCounter", "Int64*", CounterParseImplicit)
	;подсчет ДПС, олрезов и т.д.
	
	CalcElemDPS()
	CalcSpellDPS()
	CalcArmour()
	;DllCall("QueryPerformanceCounter", "Int64*", CounterCalc)
	
	
	
	Filter_Boots.Scoring()
	Filter_Gloves.Scoring()
	Filter_Helmets.Scoring()
	Filter_BodyArmours.Scoring()
	Filter_Spirit_Shields.Scoring()
	Filter_Belts.Scoring()
	Filter_Quivers.Scoring()
	
	Filter_2h_skill.Scoring()
	If Item.Success
		goto, ParseItemDataEnd
	
	
	Filter_1h_spell.Scoring()
	If Item.Success
		goto, ParseItemDataEnd
	
	Filter_WeaponDPS.Scoring(Item.ClassType)
	
	Filter_Rings.Scoring()
	Filter_Amulets.Scoring()
	
	
	
	ParseItemDataEnd:
	
	
	If Item.IsCorrupted 
	{
		TT_Result := "[Corrupted]" . TT_Result
		TT_ResultExt := "[Corrupted]" . TT_ResultExt
	}
	
	TT_Result := Item.ClassType . TT_Result . "`nFree Prefixes:	" . 3 - Item.Prefixes . "`nFree Suffixes:	" . 3 - Item.Suffixes
	TT_ResultExt := Item.ClassType . TT_ResultExt . "`nFree Prefixes:	" . 3 - Item.Prefixes . "`nFree Suffixes:	" . 3 - Item.Suffixes
	
	;TT_Result := TT_Result . TT_Affixes
	;TT_ResultExt := TT_ResultExt . TT_Affixes
	
	;TT_Result := TT_Result . "`nLinks:	" . Item.Links
	
	DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
	DllCall("QueryPerformanceFrequency", "Int64*", Frequency)
	
	;TT_Result := TT_Result . "`n" . (CounterAfter - CounterBefore)*1000/Frequency . " milliseconds"
	
	
	
	return True	
}






OnClipBoardChange:
IfWinActive, Path of Exile ahk_class Direct3DWindowClass
{
	;ParseClipBoardChanges()
}
Else
{
        ; if running tests parse clipboard regardless if PoE is foremost
        ; so we can check individual cases from test case text files
	;	ParseClipBoardChanges()
}
return


ParseClassType(BaseType, ItemStatLine)
{
	weapons_1h := "^(One Handed Axe|One Handed Mace|Bow|One Handed Sword|Wand|Sceptre|Dagger|Claw)"
	weapons_2h := "^(Two Handed Axe|Two Handed Mace|Bow|Two Handed Sword|Staff)"
	belts := " (Belt|Sash)"
	boots := " (Boots|Greaves|Shoes|Slippers)"
	helmets := " (Hat|Helmet|Bascinet|Burgonet|Cap|Tricorne|Hood|Pelt|Circlet|Cage|Sallet|Coif|Crown|Mask)"
	gloves := " (Gauntlets|Gloves|Mitts)"
	shields := " (Shield|Bundle|Buckler)"
	sceptres := " (Sekhem|Sceptre|Fetish)"
	IfNotInString, ItemStatLine, :
	{
		If (RegExMatch(ItemStatLine, weapons_1h, var))	
		{
			BaseWeapons.SetItem(BaseType, DamLo, DamHi, CC, APS)
			Item.BaseDamage[1] := DamLo
			Item.BaseDamage[2] := DamHi
			Item.BaseCrit := CC
			Item.APS := APS
			Item.GripType := "1h"
			Item.ClassType := var
			If (RegExMatch(BaseType,sceptres))
				Item.ClassType := "Sceptre"
			return
			
		} else if (RegExMatch(ItemStatLine, weapons_2h, var))	
		{
			BaseWeapons.SetItem(BaseType, DamLo, DamHi, CC, APS)
			Item.BaseDamage[1] := DamLo
			Item.BaseDamage[2] := DamHi
			Item.BaseCrit := CC
			Item.APS := APS
			Item.GripType := "2h"
			Item.ClassType := var
			return
		} else 
		{
			msgbox, Unknown Weapon Type |%ItemStatLine%|
		}
	}
	IfInString, ItemStatLine, Map Tier:
	{
		Item.IsMap := True
		Item.ClassType := "Map"
		return
	}
	IfInString, BaseType, Jewel
	{
		Item.IsJewel := True
		Item.ClassType := "Jewel"
		return
	}	
	IfInString, BaseType, Quiver
	{
		Item.IsQuiver := True
		Item.ClassType := "Quiver"
		return
	}	
	IfInString, BaseType, Jewel
	{
		Item.IsJewel := True
		Item.ClassType := "Jewel"
		return
	}	
	IfInString, BaseType, Amulet
	{
		Item.IsAmulet := True
		Item.ClassType := "Amulet"
		return
	}	
	IfInString, BaseType, Talisman
	{
		Item.IsTalisman := True
		Item.ClassType := "Talisman"
		return
	}	
	IfInString, BaseType, Ring
	{
		Item.IsRing := True
		Item.ClassType := "Ring"
		return
	}	
	If (RegExMatch(BaseType, belts))
	{
		Item.IsBelt := True
		Item.ClassType := "Belt"
		return
	}	
	If (RegExMatch(BaseType, shields))
	{
		If BaseSpiritShields.SetItem(BaseType, AR, EV, ES)
		{
			Item.BaseAR := AR
			Item.BaseEV := EV
			Item.BaseES := ES
			Item.ClassType := "Spirit Shield"
		}
		else
			Item.ClassType := "Shield"
		Item.IsShield := True
		return
	}
	If (RegExMatch(BaseType,boots))
	{
		BaseBoots.SetItem(BaseType, AR, EV, ES)
		Item.BaseAR := AR
		Item.BaseEV := EV
		Item.BaseES := ES
		Item.IsBoots := True
		Item.ClassType := "Boots"
		return
	}
	If (RegExMatch(BaseType, gloves))
	{
		If BaseGloves.SetItem(BaseType, AR, EV, ES)
		{
			Item.BaseAR := AR
			Item.BaseEV := EV
			Item.BaseES := ES
		}
		Item.IsGloves := True
		Item.ClassType := "Gloves"
		return
	}
	
	If (RegExMatch(BaseType, helmets))
	{
		If BaseHelmets.SetItem(BaseType, AR, EV, ES)
		{
			Item.BaseAR := AR
			Item.BaseEV := EV
			Item.BaseES := ES
		}
		
		Item.IsHelm := True
		Item.ClassType := "Helm"
		return
	}
	If BaseBodyArmours.SetItem(BaseType, AR, EV, ES)
	{
		Item.IsBodyArmour := True
		Item.ClassType := "BodyArmour"
		Item.BaseAR := AR
		Item.BaseEV := EV
		Item.BaseES := ES
		return
	}
	; TODO: need a reliable way to determine sub type for armour
    ; right now it's just determine anything else first if it's
    ; not that, it's armour.
}
return


GetNegativeAffixOffset(Item)
{
	NegativeAffixOffset := 0
	If (Item.HasEffect) 
	{
        ; Same with weapon skins or other effects
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsCorrupted) 
	{
        ; And corrupted items
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsMirrored) 
	{
        ; And mirrored items
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	If (Item.IsJewel) 
	{
        ; And mirrored items
		NegativeAffixOffset := NegativeAffixOffset + 1
	}
	return NegativeAffixOffset
}

ItemIsMirrored(ItemDataText)
{
	Loop, Parse, ItemDataText, `n, `r
	{
		If (A_LoopField == "Mirrored")
		{
			return True
		}
	}
	return False
}


ParseImplicit(ImplicitData)
{
	If ImplicitData
	{
		Loop, Parse, Implicit, `n, `r
		{	
			t_field1 :=
			t_field2 :=
			t_field3 :=
			t_field4 :=
			t_field5 :=
			t_value1 :=
			t_value2 :=
			t_value3 :=
			t_value4 :=
			StringSplit, t_field, A_LoopField, `t
			If RegExMatch(ImplicitData,t_field1,t_value)
			{
				Item.AddValueImplicit(t_field2,t_value1,t_field3,t_value2,t_field4,t_value3,t_field5,t_value4)
				Item.Implicit := ImplicitData
				TT_Affixes := TT_Affixes . "`nI   " . ImplicitData
				ImplicitData :=
			}
		}	
		If ImplicitData
			TT_Affixes := TT_Affixes . "`nUnknown Implicit: " . ImplicitData
	} 
	return TT_Affixes
}
return

ParseAffixes(AffixesData)
{
	loop, Parse, AffixesData, `n, `r
	{
		t_line := A_LoopField
		loop, Parse, Prefixes, `n, `r
		{
			t_field1 :=
			t_field2 :=
			t_field3 :=
			t_field4 :=
			t_field5 :=
			t_value1 :=
			t_value2 :=
			t_value3 :=
			t_value4 :=
			StringSplit, t_field, A_LoopField, `t
			If RegExMatch(t_line,t_field1,t_value)
			{
				Item.Prefixes++
				Item.AddValue(t_field2,t_value1,t_field3,t_value2,t_field4,t_value3,t_field5,t_value4)
				TT_Affixes := TT_Affixes . "`nP   " . t_line
				t_line := 
				break
				
			}
		}	
		
		If t_line
		{	
			Loop,  Parse, suffixes, `n, `r
			{
				t_field1 :=
				t_field2 :=
				t_field3 :=
				t_field4 :=
				t_field5 :=
				t_value1 :=
				t_value2 :=
				t_value3 :=
				t_value4 :=
				StringSplit, t_field, A_LoopField, `t
				If RegExMatch(t_line,t_field1,t_value)
				{
					Item.Suffixes++
					Item.AddValue(t_field2,t_value1,t_field3,t_value2,t_field4,t_value3,t_field5,t_value4)
					TT_Affixes := TT_Affixes . "`nS   " . t_line
					t_line := 
					break
				}
			}
			
		}
		If t_line
		{	
			t_field1 :=
			t_field2 :=
			t_field3 :=
			t_field4 :=
			t_field5 :=
			t_value1 :=
			t_value2 :=
			t_value3 :=
			t_value4 :=
			Loop,  Parse, affixes, `n, `r
			{
				StringSplit, t_field, A_LoopField, `t
				If RegExMatch(t_line,t_field1,t_value)
				{
					Item.Affixes++
					Item.AddValue(t_field2,t_value1,t_field3,t_value2,t_field4,t_value3,t_field5,t_value4)
					TT_Affixes := TT_Affixes . "`nA   " . t_line
					t_line := 
					break
				}
			}
			
		}
		If t_line
		{
			TT_Affixes := TT_Affixes . "`n" . "UnknownAffixes: " . t_line
		}
	}
	Return TT_Affixes
}


CalcPhysDPS()
{
	t_CraftPhysDamage := 0
	t_MultiPhysDamage := 0
	t_CraftFlatPhysDamage := 0
	t_MultiFlatPhysDamage := 0
	t_CraftIAS := 0
	t_MultiIAS := 0
	t_Prefixes := Item.Prefixes
	t_Suffixes := Item.Suffixes
	t_Multi := False
	Item.PhysDPS := (Item.BaseDamage[1] + Item.BaseDamage[2] + Item.FlatPhysDamage)/2*(120+Item.LocalPhys)/100*(Item.APS + Item.IAS/100)
	If (Item.IsFlatPhysDamage == False) and (t_Prefixes < 3)
	{
		If Item.GripType == "1h"
			t_MultiFlatPhysDamage := 33
		else
			t_MultiFlatPhysDamage := 49
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatPhysDamage := t_MultiFlatPhysDamage
			t_Multi := True
			t_TTcraft := "[FlatPhys]"
		}
		t_Prefixes++
		t_TT := t_TT . "[FlatPhys]"
	}
	If (Item.IsLocalPhysAff == False) and (t_Prefixes < 3)
	{
		t_MultiPhysDamage := 79
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftPhysDamage := t_MultiPhysDamage
			t_Multi := True
			t_TTcraft := "[Phys]"
		}
		t_TT := t_TT . "[Phys]"
	}
	If (Item.IsIAS == False) and (Item.Suffixes < 3)
	{
		t_MultiIAS := 15
		t_Suffixes++
		If (t_Multi == False) and (Item.Suffixes < 3)
		{
			t_CraftIAS := t_MultiIAS
			t_Multi := True
			t_TTcraft := "[IAS]"
		}
		t_TT := t_TT . "[IAS]"
	}
	Item.CraftPhysDps := (Item.BaseDamage[1] + Item.BaseDamage[2] + Item.FlatPhysDamage + t_CraftFlatPhysDamage)/2*(120+Item.LocalPhys+t_CraftPhysDamage)/100*Item.APS * (100 + Item.IAS + t_CraftIAS)/100
	Item.MultiPhysDps := (Item.BaseDamage[1] + Item.BaseDamage[2] + Item.FlatPhysDamage + t_MultiFlatPhysDamage)/2*(120+Item.LocalPhys+t_MultiPhysDamage)/100*Item.APS * (100 + Item.IAS + t_MultiIAS)/100
	Item.CraftedAPS := Item.APS * (100 + Item.IAS + t_CraftIAS)/100
	
	
	
}
return


CalcSpellDPS()
{
	t_CraftSpellDamage := 0
	t_MultiSpellDamage := 0
	t_CraftFlatSpellDamage := 0
	t_MultiFlatSpellDamage := 0
	t_MultiCastSpeed := 0
	t_CraftCastSpeed := 0
	t_MultiLocalElem := 0
	t_CraftLocalElem := 0
	t_Prefixes := Item.Prefixes
	t_Suffixes := Item.Suffixes
	t_Multi := False
	Item.TotalSpellDamage := Item.SpellDamage + Item.LocalElem
	t_FlatSpellDPS := (Item.FlatSpellFire + Item.FlatSpellLightning + Item.FlatSpellColdLo)/2
	
	If (Item.IsSpellDamageAff == False) and (t_Prefixes < 3)
	{
		If Item.GripType == "1h"
			t_MultiSpellDamage := 44
		else
			t_MultiSpellDamage := 68
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftSpellDamage := t_MultiSpellDamage
			t_Multi := True
			t_TTcraft := "[Spell]"
		}
		t_TT := t_TT . "[Spell]"
	}
	
	If (Item.IsFlatSpellCold == False) and (Item.IsFlatSpellFire == False) and (Item.IsFlatSpellLightning == False) and (t_Prefixes < 3)
	{
		If (Item.GripType == "1h")
			t_MultiFlatSpellDamage := 46
		else
			t_MultiFlatSpellDamage := 68
		t_Prefixes++
		t_TT := t_TT . "[FlatSpell]"
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatSpellDamage := t_MultiFlatSpellDamage
			t_Multi := True
			t_TTcraft := "[FlatSpell]"
		}
	}
	If (Item.IsCastSpeed == False) and (Item.Suffixes < 3)
	{
		t_MultiCastSpeed := 11
		t_Suffixes++
		t_TT := t_TT . "[CastSpeed]"
		If (t_Multi == False) and (Item.Suffixes < 3)
		{
			t_CraftCastSpeed := t_MultiCastSpeed
			t_Multi := True
			t_TTcraft := "[CastSpeed]"
		}
	}
	t_LocalElem := Item.LocalColdDamage + Item.LocalFireDamage + Item.LocalLightningDamage
	If (Item.IsLocalColdDamage == False) and (Item.IsLocalLightningDamage == False) and (Item.IsLocalFireDamage == False) and (t_Suffixes < 3)
	{
		t_MultiLocalElem := 19
		t_Suffixes++
		t_TT := t_TT . "[LocalElem]"
		If (t_Multi == False) and (Item.Suffixes < 3)
		{
			t_CraftLocalElem := t_MultiLocalElem
			t_Multi := True
			t_TTcraft := "[LocalElem]"
		}
	}
	
	Item.CraftTotalSpellDamage := Item.SpellDamage + Item.LocalElem + t_CraftLocalElem + t_CraftSpellDamage
	Item.CraftSpellDamage := Item.SpellDamage + t_CraftSpellDamage
	Item.MulticraftSpellDamage := Item.SpellDamage + t_MultiSpellDamage
}
return



CalcCrit()
{
	t_Suffixes := Item.Suffixes
	t_Multi := False
	
	Item.WeaponCrit := Item.BaseCrit*(100+Item.Crit)/100
	
	
	If (Item.IsCrit == False) and (t_Suffixes < 3)
		Item.CraftWeaponCrit := Item.BaseCrit*(100+27+Item.Crit)/100
}
return

CalcElemDPS()
{
	t_CraftFlatElemDamage := 0
	t_MultiFlatElemDamage := 0
	t_CraftIAS := 0
	t_MultiIAS := 0
	t_Prefixes := Item.Prefixes
	t_Suffixes := Item.Suffixes
	t_Multi := False
	
	Item.ElemDPS := (Item.FlatFire + Item.FlatCold + Item.FlatLightning)*Item.APS*(100 + Item.IAS)/100
	
	
	
	If (Item.IsFlatLightning == False) and  (t_Prefixes < 3)
	{
		If Item.GripType == "1h"
			t_MultiFlatElemDamage += := 56
		else
			t_MultiFlatElemDamage += := 85
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatElemDamage := t_MultiFlatElemDamage
			t_Multi := True
			t_TTcraft := "[FlatLightning]"
		}
		t_TT := t_TT . "[FlatLightning]"
	}
	If (Item.IsFlatFire == False) and (t_Prefixes < 3)
	{
		If Item.GripType == "1h"
			t_MultiFlatElemDamage += 54
		else
			t_MultiFlatElemDamage += 80
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatElemDamage := t_MultiFlatElemDamage
			t_Multi := True
			t_TTcraft := "[FlatFire]"
		}
		t_TT := t_TT . "[FlatFire]"
	}
	If (Item.IsFlatCold == False) and (t_Prefixes < 3)
	{
		If Item.GripType == "1h"
			t_MultiFlatElemDamage += 44
		else
			t_MultiFlatElemDamage += 65
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatElemDamage := t_MultiFlatElemDamage
			t_Multi := True
			t_TTcraft := "[FlatCold]"
		}
		t_TT := t_TT . "[FlatCold]"
	}
	If (Item.IAS == False) and (t_Suffixes < 3)
	{
		t_MultiIAS := 15
		t_TTcraft := t_TTcraft . "[IAS]"
		If (t_Multi == False) and (Item.Suffixes < 3)
		{
			t_CraftIAS := t_MultiIAS
			t_Multi := True
			t_TTcraft := "[IAS]"
		}
		
		t_Suffixes++
		t_TT := t_TT . "[IAS]"
	}
	
	Item.CraftElemDPS := (Item.FlatFire + Item.FlatCold + Item.FlatLightning + t_CraftFlatElemDamage)/2*(Item.APS * (100 + Item.IAS + t_CraftIAS)/100)
	Item.MultiElemDPS := (Item.FlatFire + Item.FlatCold + Item.FlatLightning + t_MultiFlatElemDamage)/2*(Item.APS * (100 + Item.IAS + t_MultiIAS)/100)
}
return


CalcArmour()
{
	t_MultiLocalArmour := 0
	t_CraftLocalArmour := 0
	t_CraftFlatAR := 0
	t_CraftFlatEV := 0
	t_CraftFlatES := 0
	t_MultiFlatAR := 0
	t_MultiFlatEV := 0
	t_MultiFlatES := 0
	t_CraftMaxLife := 0
	t_MultiMaxLife := 0
	t_Prefixes := Item.Prefixes
	t_Suffixes := Item.Suffixes
	t_Multi := False
	
	Item.AR := (Item.BaseAR + Item.FlatAR)*(Item.LocalArmour + 120)/100
	Item.ES := (Item.BaseES + Item.FlatES)*(Item.LocalArmour + 120)/100
	Item.EV := (Item.BaseEV + Item.FlatEV)*(Item.LocalArmour + 120)/100
	
	
	
	
	If (Item.IsLocalArmourAff == False) and (t_Prefixes < 3)
	{
		t_MultiLocalArmour := 68
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftLocalArmour := t_MultiLocalArmour
			t_TTcraft := "[LocalAR/EV/ES]"
			t_Multi := True
		}
		t_TT := t_TT . "[LocalAR/EV/ES]"
	}
	
	If (Item.IsMaxLife == False) and (t_Prefixes < 3)
	{
		t_MultiMaxLife := 64
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftMaxLife := t_MultiMaxLife
			t_TTcraft := "[MaxLife]"
			t_Multi := True
		}
		t_TT := t_TT . "[MaxLife]"
	}
	
	If (Item.IsFlatAR == False)  and (t_Prefixes < 3) and (Item.BaseES > 0)
	{
		
		t_MultiFlatES := 22
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatES := t_MultiFlatES
			t_TTcraft := "[FlatES]"
			t_Multi := True
		}
		t_TT := t_TT . "[FlatES]"
	}
	
	If (Item.IsFlatEV == False)  and (t_Prefixes < 3) and (Item.BaseEV > 0)
	{
		t_MultiFlatEV := 80
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatEV := t_MultiFlatEV
			t_TTcraft := "[FlatEV]"
			t_Multi := True
		}
		t_TT := t_TT . "[FlatEV]"
	}
	If (Item.IsFlatAR == False)  and (t_Prefixes < 3) and (Item.BaseEV > 0)
	{
		t_MultiFlatAR := 80
		t_Prefixes++
		If (t_Multi == False) and (Item.Prefixes < 3)
		{
			t_CraftFlatAR := t_MultiFlatAR
			t_TTcraft := "[FlatAR]"
			t_Multi := True
		}
		t_TT := t_TT . "[FlatAR]"
	}
	
	t_AR := (Item.BaseAR + Item.FlatAR + t_CraftFlatAR)*(Item.LocalArmour + t_CraftLocalArmour + 120)/100
	t_EV := (Item.BaseEV + Item.FlatEV + t_CraftFlatEV)*(Item.LocalArmour + t_CraftLocalArmour + 120)/100
	t_ES := (Item.BaseES + Item.FlatES + t_CraftFlatES)*(Item.LocalArmour + t_CraftLocalArmour + 120)/100
	
	Item.MultiAR := (Item.BaseAR + Item.FlatAR + t_MultiFlatAR)*(Item.LocalArmour + t_MultiLocalArmour + 120)/100
	Item.MultiEV := (Item.BaseEV + Item.FlatEV + t_MultiFlatEV)*(Item.LocalArmour + t_MultiLocalArmour + 120)/100
	Item.MultiES := (Item.BaseES + Item.FlatES + t_MultiFlatES)*(Item.LocalArmour + t_MultiLocalArmour + 120)/100
	
	If !t_AR
		t_AR := 0
	If !t_EV
		t_EV := 0
	If !t_ES
		t_ES := 0
	
	
	Item.CraftAR := t_AR
	Item.CraftEV := t_EV
	Item.CraftES := t_ES
	
	Item.CraftMaxLife := Item.MaxLife + t_CraftMaxLife
	TT_Armour := "`nAR	EV	ES	MaxLife	CraftModes"
	TT_Armour := TT_Armour . "`n" . Round(Item.AR) . "	" . Round(Item.EV) . "	" . Round(Item.ES) . "	" . Round(Item.MaxLife)
	TT_Armour := TT_Armour . "`n" . Round(Item.CraftAR) . "	" . Round(Item.CraftEV) . "	" . Round(Item.CraftES) . "	" .  Round(Item.MaxLife + t_CraftMaxLife) . "	" . t_TTcraft 
	TT_Armour := TT_Armour . "`n" . Round(Item.MultiAR) . "	" . Round(Item.MultiEV) . "	" . Round(Item.MultiES) . "	" .  Round(Item.MaxLife + t_MultiMaxLife) . "	" . t_TT 
}


CheckPhysAccuracyRating()
{
	Global Affix_ComboPhys, Affix_Acc, Affix_Phys
	
	MaxComboPhys := Affix_ComboPhys.MaxValueFromiLevel(Item.iLevel)
	MaxPhys := Affix_Phys.MaxValueFromiLevel(Item.iLevel)
	MinAcc := 5
	MaxAcc := Affix_Accuracy.MaxValueFromiLevel(Item.iLevel)
	MaxAccLight := 0
	MinAccLight := 0
	MaxComboAcc := Affix_ComboPhys.MaxValue2FromiLevel(Item.iLevel)
	
	If (Item.LightRadius == 15)
	{
		Item.Affixes--
	}
	If (Item.IsAccuracyRating == False) and (Item.IsLocalPhys == False)
	{
		return
	}
	
	If (Item.LightRadius == 10)
	{
		MaxAccLight := 40
		MinAccLight := 21
	}
	If (Item.LightRadius == 5)
	{
		MaxAccLight := 20
		MinAccLight := 10
	}
	If (Item.IsAccuracyRating == False) and (Item.IsLocalPhys <> False)
	{
		Item.IsLocalPhysAff := True
		return
	}
	If (Item.IsAccuracyRating <> False) and (Item.IsLocalPhys == False)
	{
		If (Item.IsLightRadius <> False)
		{
			If (Item.Accuracy > MaxAccLight)
			{
				Item.Affixes--
				Item.Suffixes++
				return
			}
			return
		}
		
		Item.Affixes--
		Item.Suffixes++
		return
	}
	
	If (Item.LocalPhys > MaxComboPhys)
	{
		Item.IsLocalPhysAff := True
		If (Item.LocalPhys > MaxPhys)
		{
			Item.Affixes--
			Item.Prefixes++
			
		}
		If (Item.Accuracy > (MaxComboAcc + MaxAccLight))
		{
			Item.Affixes--
			Item.Suffixes++
			
			return
		}
		If (Item.Accuracy < MinAcc + MinAccLight)
		{
			Item.Affixes--
			Item.Prefixes++
			return
		}
		return
	}
	
	Affix_ComboPhys.Value2FromValue(Item.LocalPhys, AccFromPhys_Hi, AccFromPhys_Lo)
	
	If (Item.LocalPhys <= MaxComboPhys) and (Item.LightRadius < 15) and (Item.LightRadius > 0)
	{
		
		If (Item.Accuracy > (AccFromPhys_Hi + MaxAccLight))
		{
			Item.Affixes--
			Item.Suffixes++
			Item.IsAccuracyAff := true
			return
		}
		
		If (Item.Accuracy < (MinAcc + MinAccLight))
		{
			Item.Affixes--
			If Item.LocalPhys < 40
				return
			Item.Prefixes++
			Item.IsLocalPhysAff := True
			return
		}
		return	
	}
	
	
}	
return

CheckSpellDamageMana()
{
	
	
	If (Item.IsMaxMana == False) and (Item.IsSpellDamage == False)
	{
		return
	}
	
	If (Item.IsMaxMana == False) and (Item.IsSpellDamage <> False)
	{
		Item.IsSpellDamageAff := True
		return
	}
	
	If (Item.IsMaxMana <> False) and (Item.IsSpellDamage == False)
	{
		Item.Affixes--
		Item.Prefixes++
		Item.IsMaxManaAff := True
		return
	}
	
	If (Item.ClassType == "Amulet")
	{
		Item.Prefixes++
		return
	}
	
	
	If (Item.ClassType == "Staff")
	{
		ComboMana_Hi := Affix_ComboSP_Staff.MaxValue2FromiLevel(Item.iLevel)
		Affix_ComboSP_Staff.Value2FromValue(Item.SpellDamage, ManaFromSp_Hi, ManaFromSp_Lo)
		Sp_Hi := Affix_SP_Staff.MaxValueFromiLevel(Item.iLevel)
		ComboSp_Hi := Affix_ComboSP_Staff.MaxValueFromiLevel(Item.iLevel)
	}
	else {
		ComboMana_Hi := Affix_ComboSP.MaxValue2FromiLevel(Item.iLevel)
		Affix_ComboSP.Value2FromValue(Item.SpellDamage, ManaFromSp_Hi, ManaFromSp_Lo)
		Sp_Hi := Affix_SP.MaxValueFromiLevel(Item.iLevel)
		ComboSp_Hi := Affix_ComboSP.MaxValueFromiLevel(Item.iLevel)
	}
	
	Mana_Hi := Affix_Mana.MaxValueFromiLevel(Item.iLevel)
	
	If Item.SpellDamage > Sp_Hi
	{
		
		Item.IsSpellDamageAff := True
		Item.Prefixes++
		If (Item.MaxMana > ComboMana_Hi)
		{
			Item.IsMaxManaAff := True
			Item.Prefixes++
			Item.Affixes--
			return
		}
		If (Item.MaxMana < 15)
		{
			Item.Affixes--
			return
		}
		return
	}
	
	If Item.SpellDamage > ComboSp_Hi
	{
		Item.IsSpellDamageAff := True
		Item.Prefixes++
		If (Item.MaxMana > ComboMana_Hi)
		{
			Item.IsMaxManaAff := True
			Item.Prefixes++
			Item.Affixes--
			return		
		}
		If (Item.MaxMana < 15)
		{
			Item.Affixes--
			return
		}		
		return
	}
	
	Affix_ComboSP.Value2FromValue(Item.SpellDamage, ManaFromSp_Hi,ManaFromSp_Lo)
	If Item.SpellDamage <= ComboSp_Hi
	{
		If (Item.MaxMana > ManaFromSp_Hi)
		{
			Item.Pefixes++
			Item.IsMaxManaAff := True
			Item.Affixes--
			return
		}
		If (Item.MaxMana >= ManaFromSp_Lo)
		{
			Item.Affixes--
			return
		}
		If (Item.MaxMana < 15)
		{
			If (Item.SpellDamage < 15 and Item.ClassType == "Staff")
			{
				Item.Affixes--
				return
			}
			
			If (Item.SpellDamage < 10)
			{
				Item.Affixes--
				return
			}
			Item.IsSpellDamageAff := True
			Item.Prefixes++
			return
		}
	}
}	
return

CheckArmourStun()
{
	Global Affix_ComboArmourStun, Affix_StunRecovery, Affix_Armour
	
	If (Item.IsStunRecovery == False) and (Item.IsLocalArmour == False)
	{
		return
	}
	
	If (Item.IsStunRecovery == False) and (Item.IsLocalArmour <> False)
	{
		Item.IsLocalArmourAff := True
		return
	}
	
	If (Item.IsStunRecovery <> False) and (Item.IsLocalArmour == False)
	{
		Item.Affixes--
		Item.Suffixes++
		return
	}
	
	
	
	ComboArmour_Hi :=Affix_ComboArmourStun.MaxValueFromiLevel(Item.iLevel)
	ComboStun_Hi := Affix_ComboArmourStun.MaxValue2FromiLevel(Item.iLevel)
	
	Armour_Hi := Affix_Armour.MaxValueFromiLevel(Item.iLevel)
	Stun_Hi := Affix_StunRecovery.MaxValueFromiLevel(Item.iLevel)
	Affix_ComboArmourStun.Value2FromValue(Item.LocalArmour, StunFromAr_Hi, StunFromAr_Lo)
	
	
	If Item.LocalArmour > Armour_Hi
	{
		
		Item.IsLocalArmourAff := True
		Item.Prefixes++
		If (Item.StunRecovery > ComboStun_Hi)
		{
			Item.IsStunRecoveryAff := True
			Item.Suffixes++
			Item.Affixes--
			return
		}
		If (Item.StunRecovery < 11)
		{
			Item.Affixes--
			Item.Prefixes++
			return
		}
		return
	}
	
	If Item.LocalArmour > ComboArmour_Hi
	{
		Item.IsLocalArmourAff := True
		If (Item.StunRecovery > ComboStun_Hi)
		{
			Item.IsStunRecoveryAff := True
			Item.Suffixes++
			Item.Affixes--
			return		
		}
		If (Item.StunRecovery < 11)
		{
			Item.Prefixes++
			Item.Affixes--
			return
		}
		return
	}
	
	If Item.LocalArmour <= ComboArmour_Hi
	{
		If (Item.StunRecovery > StunFromAr_Hi)
		{
			Item.Suffixes++
			Item.Affixes--
			Item.IsStunRecoveryAff := True
			return
		}
		If (Item.StunRecovery >= StunFromAr_Lo)
		{
			Item.Affixes--
			return
		}
		If (Item.StunRecovery < 11)
		{
			If Item.LocalArmour < 23
				return
			Item.IsLocalArmourAff := True
			Item.Affixes--
			Item.Prefixes++
			return
		}
	}
	
}	
return

CheckItemRarity()
{
	If (Item.IsItemRarity == False)
	{
		return
	}
	If Item.Suffixes > 2 and Item.Prefixes > 2
		msgbox, 3+ pref and suff .... 
	
	maxSuffixValue := GetItemRaritySuffix(Item.iLevel)
	maxPrefixValue := GetItemRarityPrefix(Item.iLevel)
	If (Item.ItemRarity > maxSuffixValue)
	{
		Item.Suffixes++
		Item.Prefixes++
		Item.Affixes--
		return
	}
	
	If (Item.Prefixes > 2)
	{
		If (Item.Suffixes > 2)
		{
			msgbox, ItemRarityPref : WTF with affixes and suffixes quantity?
		}
		Item.Suffixes++
		Item.Affixes--
		return
	}
	If (Item.Suffixes > 2)
	{
		If (Item.Prefixes > 2)
		{
			msgbox, ItemRaritySuff : WTF with affixes and suffixes quantity?
		}
		Item.Prefixes++
		Item.Affixes--
		return
	}
	
	If (Item.ItemRarity < 8)
	{
		Item.Affixes--
		Item.Prefixes++
		return
	}
	
	If (Item.ItemRarity < 14)
	{
		Item.SPAffixes++
		Item.Affixes--
	}
	
}
return



GetItemRaritySuffix(iLevel)
{
	If iLevel >= 84 
		return 28
	If iLevel >= 62
		return 24
	If iLevel >= 39
		return 18
	If iLevel >= 20
		return 12
}
return

GetItemRarityPrefix(iLevel)
{
	If iLevel >= 75
		return 26
	If iLevel >= 53
		return 20
	If iLevel >= 30
		return 14
	If iLevel >= 3
		return 10
}
return





