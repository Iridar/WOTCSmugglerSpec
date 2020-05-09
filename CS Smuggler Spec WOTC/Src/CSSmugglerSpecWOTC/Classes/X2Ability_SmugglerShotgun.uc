class X2Ability_SmugglerShotgun extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	Templates.AddItem(Create_Shotgun_Charge_Attack());

	return Templates;
}

static function X2AbilityTemplate Create_Shotgun_Charge_Attack(name TemplateName = 'CS_Shotgun_Charge_Attack')
{
	local X2AbilityTemplate						Template;
	local X2AbilityCost_Ammo					AmmoCost;
	local X2AbilityCost_QuickdrawActionPoints 	ActionPointCost;

	Template = class'X2Ability_RangerAbilitySet'.static.AddSwordSliceAbility(Template);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_stealth";

	// Action points setup
	ActionPointCost = new class'X2AbilityCost_QuickdrawActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.DoNotConsumeAllEffects.AddItem('SawedOffSingle_DoNotConsumeAllActionsEffect');
	Template.AbilityCosts.AddItem(ActionPointCost);	

	// Require one ammo to be present
	AmmoCost = new class'X2AbilityCost_Ammo';	
	AmmoCost.iAmmo = 1;
	AmmoCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.bAllowAmmoEffects = true;
	Template.bUseAmmoAsChargesForHUD = true;	//	Use "charges" interface to display ammo.

	Template.AbilityTargetEffects.Length = 0;

    // Put holo target effect first because if the target dies from this shot, it will be too late to notify the effect.
    Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());

    //  Various Soldier ability specific effects - effects check for the ability before applying  
	// Same as ApplyWeaponDamage, but also shreds target armor if the soldier has the Shredder ability  
    Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());

    // Stock Compatibility - deal damage to the target on a miss if you have Stock attached to the weapon	
    Template.AddTargetEffect(default.WeaponUpgradeMissDamage);

	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Run_N_Gun";
	
	//	Removed to avoid clashing "Entering concealment" speech.
	Template.ActivationSpeech = '';
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.BuildNewGameStateFn = ConcealedShotgunCharge_BuildGameState;

	return Template;
}


static simulated function XComGameState ConcealedShotgunCharge_BuildGameState(XComGameStateContext Context)
{
    local XComGameState                NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit           UnitState;
	local float                        fUnitDetectionModifier;
    
    // Cast the Game State Context to XComGameStateContext_Ability, because this is ability activation.
    AbilityContext = XComGameStateContext_Ability(Context);    

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, Context);
    
    // Prep the Unit State of the unit activating the ability for modification.
    UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));

	// Conceal the unit, if not concealed already.
	if (!UnitState.IsConcealed())
	{
		UnitState.SetIndividualConcealment(true, NewGameState);	
	}
    
	//	Record the Unit's detection modifier.
	fUnitDetectionModifier = UnitState.GetCurrentStat(eStat_DetectionModifier);
	UnitState.SetUnitFloatValue('U_Detection_Mod', fUnitDetectionModifier, eCleanup_BeginTurn);

	//	Temporarily set it to zero so the unit can approach the enemy target without breaking concealment.
	UnitState.SetCurrentStat(eStat_DetectionModifier, 0);

	//	Ability Costs applied here.
	TypicalAbility_FillOutGameState(NewGameState); 
   
    //Return the game state we have created
    return NewGameState;
}
