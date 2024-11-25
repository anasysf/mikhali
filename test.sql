USE [Prod051223]
GO
-------------------------------------------- fn_CLI_GetListTypeActivitesClients --------------------------------------------

-- ==================================================================
-- FONCTION : RECUPERATION DE LA LISTE DES Types Activites Societaire|
-- ==================================================================

-- select * from [dbo].[fn_CLI_GetListTypeActivitesSocietaire](5)
CREATE FUNCTION [dbo].[fn_CLI_GetListTypeActivitesClients]
(	
	@IdClient_		int
)
-- requete
RETURNS @Ret_ table (	
						IdTypeActivite			int,
						TypeActivite			varchar(150),
						Selected			char(1)
)
AS
BEGIN 
	INSERT INTO @Ret_
	SELECT	T.Id, T.Libelle , 
			CASE 
				WHEN exists (	SELECT * 
								FROM [dbo].[CLI_Activites] S 
								WHERE S.IdActivite = T.Id
								and S.IdClient = @IdClient_ and Actif='O'
								)
				THEN 'O'
				ELSE 'N'
			END
	FROM [dbo].[CLI_TypeActivite] T



RETURN

END


GO
-------------------------------------------- Trig_CLI_Clients_DEL --------------------------------------------
CREATE TRIGGER [dbo].[Trig_CLI_Clients_DEL] 	ON [dbo].[CLI_Clients]
    for delete
AS 
BEGIN
	SET NOCOUNT ON;
	-- ----------------------------------------------------
	-- START : Declaration & Initiailisation des variables |
	-- ----------------------------------------------------
		DECLARE @_Msg varchar(500);

		DECLARE @_IdClient INT
		DECLARE @_NumSocietaire varchar(50)

		SELECT @_IdClient = Idclient, @_NumSocietaire = NumeroSocietaire FROM deleted
	-- ------------------------------------------------------
	-- FIN   :  Declaration & Initiailisation des variables  |
	-- ------------------------------------------------------

	-------------------------------------
	--	START : suppression Client    |	
	-------------------------------------
				IF Exists (select NumeroClient from dbo.CLI_Liens Where NumeroClient =  @_NumSocietaire and IdLienParente = 92)  BEGIN
					set @_Msg = 'Erreur Suppression, Vous ne pouvez pas supprimer un beneficiaire effectif  ' + cast(@_NumSocietaire as varchar)
					goto errTransaction	 
				END
	--------------------------------------
	--	END : suppression Client      |	
	--------------------------------------

	-- ------------------------------------
	-- START :  Erreur transaction        |
	-- ------------------------------------
		return


			errTransaction:
				set @_Msg = 'Trig_CLI_Clients_DEL >>> ' + @_Msg
				rollback transaction
				raiserror( @_Msg, 16, 1 )
				return

	-- ------------------------------------
	-- FIN   :  Erreur transaction        |
	-- ------------------------------------
END
GO
-------------------------------------------- RCV_PS_IdentificationClients --------------------------------------------
-- exec ps_CPIdentification  
-- Select * from CP_Contentieux where referenceCtx = '371CP201500096'
-- exec  [RCV_IdentificationQuittances] @Souscripteur_ = NULL, @IdEntite_ = NULL, @IdSite_ = 101, @Msg_ = null
CREATE        Procedure [dbo].[RCV_PS_IdentificationClients]
					@IdClient_          Int          = Null,
					@Assure_            varchar(255) = NULL,				
					@CIN_               varchar(50) = NULL,
					@Souscripteur_      varchar(255) = NULL,
					@Police_            varchar(50) = null,
					@NumQuittance_      varchar(50) = null,
					@IdEntite_          int = null,
					@IdSite_            int = null
AS
Begin

Declare  @Sql nvarchar(4000), @paramlist nvarchar(4000), @Inner nvarchar(4000),
		 @Condition nvarchar(4000), @Param nvarchar(4000), @Order nvarchar(4000), @Group nvarchar(4000),
		 @Virgule varchar(5), @Pos int, @con varchar(5000)

Select @Param     = 'Select Distinct C.IdClient , C.NomClient , C.CIN'
Select @Inner     = 'From dbo.RCV_Quittances Q '
--Left JOIN RCV_NatureQuittance NQ ON(NQ.IdNature = Q.IdNature) '
Select @Inner     = @INNER +'INNER JOIN CLI_Clients C ON (C.IdClient = Q.IdSouscripteur)'
Select @Inner     = @INNER +'INNER JOIN dbo.STD_Sites S ON (S.idSite = Q.IdSite)'
Select @Inner     = @INNER +'Left JOIN dbo.RCV_StdStatutQuittance SQ ON (SQ.IdStatut = Q.IdStatut)'


Select @Condition = 'Where 1 = 1 and Encaissee = ''N'''
--select @Group	  = 'Group By D.Contentieux, D.referenceCtx, D.DateSin, D.DateDeclaration, D.Police, C.RaisonSociale, D.SortSin, D.IdSite, D.NomAssure ,PR.Libelle , D.ReferenceExterne'	
Select @Order     = 'Order By C.NomClient '

-- @Souscripteur_
If @Souscripteur_  is not null and @Souscripteur_  <> '' BEGIN
	select @Condition = @Condition + ' AND  C.NomClient like ''%'' + @Souscripteur_ + ''%'' '
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @CIN_
If @CIN_  is not null AND @CIN_  <> '' BEGIN
    select @Condition = @Condition + ' AND  C.CIN like ''%'' + @CIN_ + ''%'' ' 
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @Police_
If @Police_  is not null and @Police_  <> '' BEGIN
	select @Condition = @Condition + ' AND  Q.Police like ''%'' + @Police_ + ''%'' ' 
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @NumQuittance_
If @NumQuittance_  is not null AND @NumQuittance_  <> '' BEGIN
    select @Condition = @Condition + ' AND  Q.NumQuittance like ''%'' + @NumQuittance_ + ''%'' ' 	
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @IdSite_
If @IdSite_  is not null and @IdSite_  <> '' BEGIN
	select @Condition = @Condition + ' AND  Q.IdSite = ' + cast(@IdSite_ as varchar(30))
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @IdEntite_
--If @IdEntite_  is not null AND @IdEntite_  <> '' BEGIN
   -- select @Condition = @Condition + ' AND  Q.IdEntite = '	+ cast(@IdEntite_ as varchar(30))
	--Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
--END


----- Set la requête SQL ------------
Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition + ' ' + ' ' + @Order


SELECT @paramlist = '@Assure_           varchar(255) ,				
					@CIN_			    varchar(50)  ,
					@Souscripteur_      varchar(255) ,
					@Police_            varchar(50)  ,
					@NumQuittance_      varchar(50)  ,
					@IdEntite_          int          ,
					@IdSite_            int          '		
			
print @sql
 
EXEC sp_executesql @sql, @paramlist,

        @Assure_, @CIN_, @Souscripteur_, @Police_, @NumQuittance_, @IdEntite_, @IdSite_
END

-- exec [ps_CPIdentification] @ReferenceCtx = '371CP201500096'
-- execute ps_CPIdentification @ReferenceCtx = '371CP201500096'
-- exec ps_SinATIdentification @dateSinistreDeb = '10/06/2014',@dateSinistreFin='10/07/2014' 
-- execute ps_SinATIdentification @IdLieuSurvenance= '0',@montantCheque= 27.76
-- execute ps_SinATIdentification @IdLieuSurvenance= '0',@medecinConseil= '0',@avocatConseil= '0',@tribunal= '0',@IdSite_ = -1


GO
-------------------------------------------- fn_CLI_GetListTypeSportsClients --------------------------------------------
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- select * from [dbo].[fn_CLI_GetListTypeSportsClients](5)
CREATE FUNCTION [dbo].[fn_CLI_GetListTypeSportsClients]
(	
	@IdClient_		int
)
RETURNS @Ret_ table (	
						IdTypeSport			int,
						TypeSport			varchar(150),
						Selected			char(1)
)
AS
BEGIN 
	INSERT INTO @Ret_
	SELECT	t.Id, t.Libelle , 
			CASE 
				WHEN exists (	SELECT * 
								FROM dbo.CLI_Sports s 
								WHERE s.IdSport = t.Id
								and s.IdClient = @IdClient_ and Actif='O'
								)
				THEN 'O'
				ELSE 'N'
			END
	FROM dbo.CLI_TypeSports t



RETURN

END


GO
-------------------------------------------- MIG_Clients_MCMA_Full --------------------------------------------

CREATE PROCEDURE [dbo].[MIG_Clients_MCMA_Full] 

AS BEGIN
	set nocount on
	set implicit_transactions off

	---------- TABLES UTILISÉES -----------------

		-- NtsAuto.dbo.StdClients
		-- NtsAuto.dbo.StdClients
		-- SI_Migration.dbo.CLI_Clients

	---------------------------------------------
	------------------------------------------
	-- START : DECLARATION DES VARIABLES	   								              
	------------------------------------------
		
		DECLARE	@_CommitVar				Int,  
				@_Msg					Varchar(1000), 
				@_DateMigration			Datetime, 
				@_ProcessMigre			varchar(100),
				@_MotifRejet			varchar(100),
				@_CountClient			int,
				@_CountClientWDIAM		int,
				@_IdSociete				int,
				@_IsRIB					char(1)='N',
				@_RIB					varchar(50),
				@_IdClientMAMDAInsere   int,
				@_IdClientMCMAInsere	int
		
		Declare @_TempClient table(IdCLient int)

		Declare @IdClient_MAMDA int
		Declare @IdClient_MCMA int
		Declare @IdProfession_MAMDA int
		Declare @IdProfession_MCMA int
		Declare @IdProfession int
		Declare @IdVille int
		Declare @Libelle varchar(500)


	------------------------------------------
	-- END : DECLARATION DES VARIABLES	   								              
	------------------------------------------

	------------------------------------------
	-- START : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

		SELECT	@_DateMigration = GetDate()

	------------------------------------------
	-- END : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

	-- ======================================================================================
	--					START : Transaction [_MigrerClients]				
	-- ======================================================================================

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEMP_MIG_CLIENTS_ALL]') AND type in (N'U'))
		BEGIN
			CREATE TABLE [dbo].TEMP_MIG_CLIENTS_ALL(
				[IdClientNts] [int] NOT NULL,
				[IdSociete] [int] NOT NULL,
				[Commentaire][varchar] (100) NOT NULL
			) 

			CREATE INDEX indx_Cli_Migr1 ON TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete);  
			CREATE INDEX indx_Cli_Migr2 ON TEMP_MIG_CLIENTS_ALL (IdClientNts);
		END
		-----------------------------------------------------------------------------------------------
		---									INSERTION CLIENTS MCMA
		-----------------------------------------------------------------------------------------------


		--- Désactivation des triggers
		
		ALTER TABLE CLI_Clients DISABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes DISABLE TRIGGER ALL

		--------------------------------------------------

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		SELECT    IdClient,3,'Client'
		FROM NtsAuto.dbo.StdClients C
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 3
		where s.IdNatureSite = 2 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = C.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3 , 'Historique_Client'
		from NtsAuto.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = h.IdClient) 
		and REF_AGENT not like '%MIG_SIN%'


		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdAssure),3 ,'Historique_Assure'
		from NtsAuto.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = h.IdAssure) 
		and REF_AGENT not like '%MIG_SIN%'

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3 ,'RDPolice_Client'
		from NtsAuto.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdProduit <>33
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = h.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdASSURE),3 ,'RDPolice_Assure'
		from NtsAuto.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdProduit <>33
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = h.IdASSURE)

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3 ,'Encaissement'
		from NtsAuto.dbo.StdIEncaisse h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = h.IdClient)


		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3,'Quittance' 
		from NtsAuto.dbo.StdQuittances h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 3 and IdClientNts = h.IdClient)

				
		------- Migration de données Client  MCMA
		INSERT INTO [dbo].[CLI_Clients]
		([IdSociete],				[IdSource],						[IdSite],					[CodeSite]
		,[Particulier],				[NomClient],					[Nom],						[Prenom1]
		,[CIN],						[DateDelivranceCIN],			[LieuDelivranceCIN],		[Sexe]
		,[VIP],						[IdTypeVIP],					[IdQualite],				[IdSecteur]
		,[IdProfession],				[IdOrganisme],					[DateNaissance],			[IdVilleNaissance]
		,[NumPermis],				[IdTypePermis],					[DateDelivrancePermis],		[IdLieuDelivrancePermis]
		,[DateAccident],				[DateInvalidite],				[NomSociete],				[NomAbrege]
		,[NumIdentificationFiscale],	[NumPatente],					[NumSocietaireHolding],		[NomSocietaireHolding]
		,[NumeroSocietaire],			[AdresseComplete],				[DateCreation]
		,[DateMAJ],					[OperateurCreation],			[OperateurMaj],				[Statut]
		,[TypeAdresse],				[NumeroAdresse],				[IdVoie],					[ComplementAdresseRurale]
		,[CodePostal],				[IdVille],						[IdPays],					[Kiyada]
		,[Douar],					[Province],						[Commune],					[Email]
		,[ComplementAdresseUrbaine],	[Portable],						[Fixe],						[Fax]
		,[Actif],					[IdClientNts],					[Conforme],					[IdOperateurConforme]
		,[DateConforme],			migre,							DateMigration)
		SELECT						
		3,							NULL,							S.IdSite,					S.CodeSite,
		isnull(C.Particulier,'N'),	C.RaisonSociale,				CASE 
																		WHEN isnull(C.Particulier,'N') = 'O' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		CASE 
			WHEN isnull(C.Particulier,'N') = 'O' THEN CIN_PAT 
			ELSE NULL 
		END,						NULL,							NULL,						NULL,
		isnull(VIP,'N'),			NULL,							Q.IdQualite,			NULL,
		P.IdProfession,				NULL,							CASE 
																		WHEN DateNaissance ='01/01/1900' THEN NULL
																		ELSE DateNaissance
																	END,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						NULL,							CASE 
																		WHEN isnull(C.Particulier,'N') = 'N' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		NULL,						CASE 
										WHEN isnull(C.Particulier,'N') = 'N' THEN CIN_PAT 
										ELSE NULL 
									END,							NULL,						NULL,
		CASE WHEN isnull(C.Matricule,'')='' THEN CAST (C.IdClient as varchar(50)) ELSE C.Matricule END,
				
									C.ADRESSE1 + ' ' +C.ADRESSE2,						C.DateCreation,
		DateMAJ,					U.User_Id,						U.User_Id,					'U',
		'U',						NULL,							NULL,						C.ADRESSE1 + ' ' +C.ADRESSE2,
		NULL,						V.IdVille,						NULL,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP1 like '6%' OR C.TELEP1 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP2 like '6%' OR C.TELEP2 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,					
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.FAX like '6%' OR C.FAX like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,
		NULL,						C.IdClient		,					'N',					NULL,
		NULL,						'O',		@_DateMigration																									
		from NtsAuto.dbo.StdClients C
		INNER JOIN TEMP_MIG_CLIENTS_ALL MG 
			on MG.IdClientNts = c.IdClient and MG.IdSociete = 3
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 3
		left join REF_Villes V
			on V.IdVilleNts = C.IdVille and V.IdSociete = 3
		left join REF_Professions P 
			on P.IdProfessionNts = C.IdProfession and P.IdSociete = 3
		left join REF_Qualites Q
			on Q.IdQualiteNts = C.IdQualite and Q.IdSociete = 3
		left join ACL_UsersSites U
			on U.User_Id_Nts = C.IdOperateur and U.Societe_Id = 3
		where MG.IdSociete = 3
		and not exists (select CLI.IdClient from CLI_Clients CLI where CLI.IdClientNts = C.IdClient and CLI.IdSociete = 3)

		UPDATE AUTO_Conventions
		set IdSocietaire = CL.IdClient,
			IdSite = CL.IdSite,
			Police = V.Police
		from AUTO_Conventions C
		inner join NtsAuto.dbo.OtoConventionsIdt V
			on C.IdConventionW = V.IdConvention and C.IdSociete = 3
		inner join CLI_Clients CL
			on CL.IdClientNts = V.IdSouscripteur and CL.IdSociete = 3

		--- Activation des triggers
		
		ALTER TABLE CLI_Clients ENABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes ENABLE TRIGGER ALL

	-- ======================================================================================
	--					END : Transaction [_MigrerClients]				
	-- ======================================================================================

		
	 RETURN 0

end































GO
-------------------------------------------- MIG_Clients_MCMA --------------------------------------------

CREATE PROCEDURE [dbo].[MIG_Clients_MCMA] (@IdSite_ int, @IdSociete_ int)

AS BEGIN
	set nocount on
	set implicit_transactions off

	---------- TABLES UTILISÉES -----------------

		-- NtsAuto.dbo.StdClients
		-- NtsAuto.dbo.StdClients
		-- SI_Migration.dbo.CLI_Clients

	---------------------------------------------
	------------------------------------------
	-- START : DECLARATION DES VARIABLES	   								              
	------------------------------------------
		
		DECLARE	@_CommitVar				Int,  
				@_Msg					Varchar(1000), 
				@_DateMigration			Datetime, 
				@_ProcessMigre			varchar(100),
				@_MotifRejet			varchar(100),
				@_CountClient			int,
				@_CountClientWDIAM		int,
				@_IdSociete				int,
				@_IsRIB					char(1)='N',
				@_RIB					varchar(50),
				@_IdClientMAMDAInsere   int,
				@_IdClientMCMAInsere	int
		
		Declare @_TempClient table(IdCLient int)

		Declare @IdClient_MAMDA int
		Declare @IdClient_MCMA int
		Declare @IdProfession_MAMDA int
		Declare @IdProfession_MCMA int
		Declare @IdProfession int
		Declare @IdVille int
		Declare @Libelle varchar(500)


	------------------------------------------
	-- END : DECLARATION DES VARIABLES	   								              
	------------------------------------------

	------------------------------------------
	-- START : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

		SELECT	@_DateMigration = GetDate()

	------------------------------------------
	-- END : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

	-- ======================================================================================
	--					START : Transaction [_MigrerClients]				
	-- ======================================================================================

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEMP_MIG_CLIENTS]') AND type in (N'U'))
		BEGIN
			CREATE TABLE [dbo].TEMP_MIG_CLIENTS(
				[IdClientNts] [int] NOT NULL,
				[IdSociete] [int] NOT NULL,
				[IdSite] [int] NOT NULL,
				[Commentaire][varchar] (100) NOT NULL
			) 

			CREATE INDEX indx_Cli_1 ON TEMP_MIG_CLIENTS (IdClientNts,IdSociete,IdSite);  
			CREATE INDEX indx_Cli_2 ON TEMP_MIG_CLIENTS (IdClientNts,IdSociete);  
			CREATE INDEX indx_Cli_3 ON TEMP_MIG_CLIENTS (IdClientNts,IdSite);  
			CREATE INDEX indx_Cli_4 ON TEMP_MIG_CLIENTS (IdClientNts);
		END

		-----------------------------------------------------------------------------------------------
		---									INSERTION CLIENTS MCMA
		-----------------------------------------------------------------------------------------------


		--- Désactivation des triggers
		
		ALTER TABLE CLI_Clients DISABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes DISABLE TRIGGER ALL

		--------------------------------------------------

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		SELECT    IdClient,3,'Client',c.IdSite
		FROM NtsAuto.dbo.StdClients C
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 3
		where s.IdNatureSite = 2 and c.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = C.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),3 , 'Historique_Client',h.IdSite
		from NtsAuto.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = h.IdClient) 
		and REF_AGENT not like '%MIG_SIN%'


		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdAssure),3 ,'Historique_Assure',h.IdSite
		from NtsAuto.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = h.IdAssure) 
		and REF_AGENT not like '%MIG_SIN%'

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),3 ,'RDPolice_Client',h.IdSite
		from NtsAuto.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdProduit <>33 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = h.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,Idsite)
		select distinct(h.IdASSURE),3 ,'RDPolice_Assure', h.IdSite
		from NtsAuto.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdProduit <>33 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = h.IdASSURE)

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),3 ,'Encaissement', h.IdSite
		from NtsAuto.dbo.StdIEncaisse h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdSite = @IdSite_ 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = h.IdClient)


		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire, IdSite)
		select distinct(h.IdClient),3,'Quittance' ,h.IdSite
		from NtsAuto.dbo.StdQuittances h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite <>4 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 3 and IdClientNts = h.IdClient)

				
		------- Migration de données Client  MCMA
		INSERT INTO [dbo].[CLI_Clients]
		([IdSociete],				[IdSource],						[IdSite],					[CodeSite]
		,[Particulier],				[NomClient],					[Nom],						[Prenom1]
		,[CIN],						[DateDelivranceCIN],			[LieuDelivranceCIN],		[Sexe]
		,[VIP],						[IdTypeVIP],					[IdQualite],				[IdSecteur]
		,[IdProfession],				[IdOrganisme],					[DateNaissance],			[IdVilleNaissance]
		,[NumPermis],				[IdTypePermis],					[DateDelivrancePermis],		[IdLieuDelivrancePermis]
		,[DateAccident],				[DateInvalidite],				[NomSociete],				[NomAbrege]
		,[NumIdentificationFiscale],	[NumPatente],					[NumSocietaireHolding],		[NomSocietaireHolding]
		,[NumeroSocietaire],			[AdresseComplete],				[DateCreation]
		,[DateMAJ],					[OperateurCreation],			[OperateurMaj],				[Statut]
		,[TypeAdresse],				[NumeroAdresse],				[IdVoie],					[ComplementAdresseRurale]
		,[CodePostal],				[IdVille],						[IdPays],					[Kiyada]
		,[Douar],					[Province],						[Commune],					[Email]
		,[ComplementAdresseUrbaine],	[Portable],						[Fixe],						[Fax]
		,[Actif],					[IdClientNts],					[Conforme],					[IdOperateurConforme]
		,[DateConforme],			migre,							DateMigration)
		SELECT						
		3,							NULL,							S.IdSite,					S.CodeSite,
		isnull(C.Particulier,'N'),	C.RaisonSociale,				CASE 
																		WHEN isnull(C.Particulier,'N') = 'O' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		CASE 
			WHEN isnull(C.Particulier,'N') = 'O' THEN CIN_PAT 
			ELSE NULL 
		END,						NULL,							NULL,						NULL,
		isnull(VIP,'N'),			NULL,							Q.IdQualite,			NULL,
		P.IdProfession,				NULL,							CASE 
																		WHEN DateNaissance ='01/01/1900' THEN NULL
																		ELSE DateNaissance
																	END,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						NULL,							CASE 
																		WHEN isnull(C.Particulier,'N') = 'N' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		NULL,						CASE 
										WHEN isnull(C.Particulier,'N') = 'N' THEN CIN_PAT 
										ELSE NULL 
									END,							NULL,						NULL,
		CASE WHEN isnull(C.Matricule,'')='' THEN CAST (C.IdClient as varchar(50)) ELSE C.Matricule END,
				
									C.ADRESSE1 + ' ' +C.ADRESSE2,						C.DateCreation,
		DateMAJ,					U.User_Id,						U.User_Id,					'U',
		'U',						NULL,							NULL,						C.ADRESSE1 + ' ' +C.ADRESSE2,
		NULL,						V.IdVille,						NULL,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP1 like '6%' OR C.TELEP1 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP2 like '6%' OR C.TELEP2 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,					
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.FAX like '6%' OR C.FAX like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,
		NULL,						C.IdClient		,					'N',					NULL,
		NULL,						'O',			@_DateMigration																									
		from NtsAuto.dbo.StdClients C
		INNER JOIN TEMP_MIG_CLIENTS MG 
			on MG.IdClientNts = c.IdClient and MG.IdSociete = 3
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 3
		left join REF_Villes V
			on V.IdVilleNts = C.IdVille and V.IdSociete = 3
		left join REF_Professions P 
			on P.IdProfessionNts = C.IdProfession and P.IdSociete = 3
		left join REF_Qualites Q
			on Q.IdQualiteNts = C.IdQualite and Q.IdSociete = 3
		left join ACL_UsersSites U
			on U.User_Id_Nts = C.IdOperateur and U.Societe_Id = 3
		where MG.IdSociete = 3 and mg.IdSite = @IdSite_
		and not exists (select CLI.IdClient from CLI_Clients CLI where CLI.IdClientNts = C.IdClient and CLI.IdSociete = 3)

		UPDATE AUTO_Conventions
		set IdSocietaire = CL.IdClient,
			IdSite = CL.IdSite,
			Police = V.Police
		from AUTO_Conventions C
		inner join NtsAuto.dbo.OtoConventionsIdt V
			on C.IdConventionW = V.IdConvention and C.IdSociete = 3
		inner join CLI_Clients CL
			on CL.IdClientNts = V.IdSouscripteur and CL.IdSociete = 3

		--- Activation des triggers
		
		ALTER TABLE CLI_Clients ENABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes ENABLE TRIGGER ALL

	-- ======================================================================================
	--					END : Transaction [_MigrerClients]				
	-- ======================================================================================

		
	 RETURN 0

end































GO
-------------------------------------------- MIG_Clients_MAMDA_Full --------------------------------------------

CREATE PROCEDURE [dbo].[MIG_Clients_MAMDA_Full] 

AS BEGIN
	set nocount on
	set implicit_transactions off

	---------- TABLES UTILISÉES -----------------

		-- NtsAuto_MAMDA.dbo.StdClients
		-- NtsAuto.dbo.StdClients
		-- SI_Migration.dbo.CLI_Clients

	---------------------------------------------
	------------------------------------------
	-- START : DECLARATION DES VARIABLES	   								              
	------------------------------------------
		
		DECLARE	@_CommitVar				Int,  
				@_Msg					Varchar(1000), 
				@_DateMigration			Datetime, 
				@_ProcessMigre			varchar(100),
				@_MotifRejet			varchar(100),
				@_CountClient			int,
				@_CountClientWDIAM		int,
				@_IdSociete				int,
				@_IsRIB					char(1)='N',
				@_RIB					varchar(50),
				@_IdClientMAMDAInsere   int,
				@_IdClientMCMAInsere	int
		
		Declare @_TempClient table(IdCLient int)

		Declare @IdClient_MAMDA int
		Declare @IdClient_MCMA int
		Declare @IdProfession_MAMDA int
		Declare @IdProfession_MCMA int
		Declare @IdProfession int
		Declare @IdVille int
		Declare @Libelle varchar(500)


	------------------------------------------
	-- END : DECLARATION DES VARIABLES	   								              
	------------------------------------------

	------------------------------------------
	-- START : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

		SELECT	@_DateMigration = GetDate()

	------------------------------------------
	-- END : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

	-- ======================================================================================
	--					START : Transaction [_MigrerClients]				
	-- ======================================================================================
		
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEMP_MIG_CLIENTS_ALL]') AND type in (N'U'))
		BEGIN
			CREATE TABLE [dbo].TEMP_MIG_CLIENTS_ALL(
				[IdClientNts] [int] NOT NULL,
				[IdSociete] [int] NOT NULL,
				[Commentaire][varchar] (100) NOT NULL
			) 

			CREATE INDEX indx_Cli_Migr1 ON TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete);  
			CREATE INDEX indx_Cli_Migr2 ON TEMP_MIG_CLIENTS_ALL (IdClientNts);
		END
		-----------------------------------------------------------------------------------------------
		---									INSERTION CLIENTS MAMDA
		-----------------------------------------------------------------------------------------------




		--- Désactivation des triggers
		
		ALTER TABLE CLI_Clients DISABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes DISABLE TRIGGER ALL

		--------------------------------------------------

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		SELECT    IdClient,1,'Client'
		FROM NtsAuto_MAMDA.dbo.StdClients C
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = C.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),1 , 'Historique_Client'
		from NtsAuto_MAMDA.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = h.IdClient) 
		and REF_AGENT not like '%MIG_SIN%'


		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdAssure),1 ,'Historique_Assure'
		from NtsAuto_MAMDA.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = h.IdAssure) 
		and REF_AGENT not like '%MIG_SIN%'

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),1 ,'RDPolice_Client'
		from NtsAuto_MAMDA.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdProduit <>33
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = h.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdASSURE),1 ,'RDPolice_Assure'
		from NtsAuto_MAMDA.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdProduit <>33
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = h.IdASSURE)

		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),1 ,'Encaissement'
		from NtsAuto_MAMDA.dbo.StdIEncaisse h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = h.IdClient)


		INSERT INTO TEMP_MIG_CLIENTS_ALL (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),1,'Quittance' 
		from NtsAuto_MAMDA.dbo.StdQuittances h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_ALL where IdSociete = 1 and IdClientNts = h.IdClient)

				
		----- Migration de données Client  MAMDA
		INSERT INTO [dbo].[CLI_Clients]
		([IdSociete],				[IdSource],						[IdSite],					[CodeSite]
		,[Particulier],				[NomClient],					[Nom],						[Prenom1]
		,[CIN],						[DateDelivranceCIN],			[LieuDelivranceCIN],		[Sexe]
		,[VIP],						[IdTypeVIP],					[IdQualite],				[IdSecteur]
		,[IdProfession],				[IdOrganisme],					[DateNaissance],			[IdVilleNaissance]
		,[NumPermis],				[IdTypePermis],					[DateDelivrancePermis],		[IdLieuDelivrancePermis]
		,[DateAccident],				[DateInvalidite],				[NomSociete],				[NomAbrege]
		,[NumIdentificationFiscale],	[NumPatente],					[NumSocietaireHolding],		[NomSocietaireHolding]
		,[NumeroSocietaire],			[AdresseComplete],				[DateCreation]
		,[DateMAJ],					[OperateurCreation],			[OperateurMaj],				[Statut]
		,[TypeAdresse],				[NumeroAdresse],				[IdVoie],					[ComplementAdresseRurale]
		,[CodePostal],				[IdVille],						[IdPays],					[Kiyada]
		,[Douar],					[Province],						[Commune],					[Email]
		,[ComplementAdresseUrbaine],	[Portable],						[Fixe],						[Fax]
		,[Actif],					[IdClientNts],					[Conforme],					[IdOperateurConforme]
		,[DateConforme],			Migre,							DateMigration)
		SELECT						
		1,							NULL,							S.IdSite,					S.CodeSite,
		isnull(C.Particulier,'N'),	C.RaisonSociale,				CASE 
																		WHEN isnull(C.Particulier,'N') = 'O' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		CASE 
			WHEN isnull(C.Particulier,'N') = 'O' THEN CIN_PAT 
			ELSE NULL 
		END,						NULL,							NULL,						NULL,
		isnull(VIP,'N'),			NULL,							Q.IdQualite,			NULL,
		P.IdProfession,				NULL,							CASE 
																		WHEN DateNaissance ='01/01/1900' THEN NULL
																		ELSE DateNaissance
																	END,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						NULL,							CASE 
																		WHEN isnull(C.Particulier,'N') = 'N' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		NULL,						CASE 
										WHEN isnull(C.Particulier,'N') = 'N' THEN CIN_PAT 
										ELSE NULL 
									END,							NULL,						NULL,
		CASE WHEN isnull(C.Matricule,'')='' THEN CAST (C.IdClient as varchar(50)) ELSE C.Matricule END,
				
									C.ADRESSE1 + ' ' +C.ADRESSE2,						C.DateCreation,
		DateMAJ,					U.User_Id,						U.User_Id,					'U',
		'U',						NULL,							NULL,						C.ADRESSE1 + ' ' +C.ADRESSE2,
		NULL,						V.IdVille,						NULL,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP1 like '6%' OR C.TELEP1 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP2 like '6%' OR C.TELEP2 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,					
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.FAX like '6%' OR C.FAX like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,
		NULL,						C.IdClient		,					'N',					NULL,
		NULL,						'O',			@_DateMigration																									
		from NtsAuto_MAMDA.dbo.StdClients C
		INNER JOIN TEMP_MIG_CLIENTS_ALL MG 
			on MG.IdClientNts = c.IdClient and MG.IdSociete = 1
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 1
		left join REF_Villes V
			on V.IdVilleNts = C.IdVille and V.IdSociete = 1
		left join REF_Professions P 
			on P.IdProfessionNts = C.IdProfession and P.IdSociete = 1
		left join REF_Qualites Q
			on Q.IdQualiteNts = C.IdQualite and Q.IdSociete = 1
		left join ACL_UsersSites U
			on U.User_Id_Nts = C.IdOperateur and U.Societe_Id = 1 
		where MG.IdSociete = 1
		and not exists (select IdClient from CLI_Clients where IdClientNts = c.IdClient and IdSociete = 1)


		UPDATE AUTO_Conventions
		set IdSocietaire = CL.IdClient,
			IdSite = CL.IdSite,
			Police = V.Police
		from AUTO_Conventions C
		inner join NtsAuto_Mamda.dbo.OtoConventionsIdt V
			on C.IdConventionW = V.IdConvention and C.IdSociete = 1
		inner join CLI_Clients CL
			on CL.IdClientNts = V.IdSouscripteur and CL.IdSociete = 1

		--- Activation des triggers
		
		ALTER TABLE CLI_Clients ENABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes ENABLE TRIGGER ALL

	-- ======================================================================================
	--					END : Transaction [_MigrerClients]				
	-- ======================================================================================

		
	 RETURN 0

end































GO
-------------------------------------------- MIG_Clients_MAMDA --------------------------------------------

CREATE PROCEDURE [dbo].[MIG_Clients_MAMDA] (@IdSite_ int, @IdSociete_ int)

AS BEGIN
	set nocount on
	set implicit_transactions off

	---------- TABLES UTILISÉES -----------------

		-- NtsAuto_MAMDA.dbo.StdClients
		-- NtsAuto.dbo.StdClients
		-- SI_Migration.dbo.CLI_Clients

	---------------------------------------------
	------------------------------------------
	-- START : DECLARATION DES VARIABLES	   								              
	------------------------------------------
		
		DECLARE	@_CommitVar				Int,  
				@_Msg					Varchar(1000), 
				@_DateMigration			Datetime, 
				@_ProcessMigre			varchar(100),
				@_MotifRejet			varchar(100),
				@_CountClient			int,
				@_CountClientWDIAM		int,
				@_IdSociete				int,
				@_IsRIB					char(1)='N',
				@_RIB					varchar(50),
				@_IdClientMAMDAInsere   int,
				@_IdClientMCMAInsere	int
		
		Declare @_TempClient table(IdCLient int)

		Declare @IdClient_MAMDA int
		Declare @IdClient_MCMA int
		Declare @IdProfession_MAMDA int
		Declare @IdProfession_MCMA int
		Declare @IdProfession int
		Declare @IdVille int
		Declare @Libelle varchar(500)


	------------------------------------------
	-- END : DECLARATION DES VARIABLES	   								              
	------------------------------------------

	------------------------------------------
	-- START : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

		SELECT	@_DateMigration = GetDate()

	------------------------------------------
	-- END : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

	-- ======================================================================================
	--					START : Transaction [_MigrerClients]				
	-- ======================================================================================
		
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEMP_MIG_CLIENTS]') AND type in (N'U'))
		BEGIN
			CREATE TABLE [dbo].TEMP_MIG_CLIENTS(
				[IdClientNts] [int] NOT NULL,
				[IdSociete] [int] NOT NULL,
				[IdSite] [int] NOT NULL,
				[Commentaire][varchar] (100) NOT NULL
			) 

			CREATE INDEX indx_Cli_1 ON TEMP_MIG_CLIENTS (IdClientNts,IdSociete,IdSite);  
			CREATE INDEX indx_Cli_2 ON TEMP_MIG_CLIENTS (IdClientNts,IdSociete);  
			CREATE INDEX indx_Cli_3 ON TEMP_MIG_CLIENTS (IdClientNts,IdSite);  
			CREATE INDEX indx_Cli_4 ON TEMP_MIG_CLIENTS (IdClientNts);
		END

		-----------------------------------------------------------------------------------------------
		---									INSERTION CLIENTS MAMDA
		-----------------------------------------------------------------------------------------------

		--- Désactivation des triggers
		
		ALTER TABLE CLI_Clients DISABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes DISABLE TRIGGER ALL

		--------------------------------------------------

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire, IdSite)
		SELECT    IdClient,1,'Client',c.IdSite
		FROM NtsAuto_MAMDA.dbo.StdClients C
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and C.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = C.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),1 , 'Historique_Client',h.IdSite
		from NtsAuto_MAMDA.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = h.IdClient) 
		and REF_AGENT not like '%MIG_SIN%'


		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdAssure),1 ,'Historique_Assure',h.IdSite
		from NtsAuto_MAMDA.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = h.IdAssure) 
		and REF_AGENT not like '%MIG_SIN%'

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),1 ,'RDPolice_Client',h.IdSite
		from NtsAuto_MAMDA.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdProduit <>33 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = h.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdASSURE),1 ,'RDPolice_Assure',h.IdSite
		from NtsAuto_MAMDA.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdProduit <>33 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = h.IdASSURE)

		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),1 ,'Encaissement',h.IdSite
		from NtsAuto_MAMDA.dbo.StdIEncaisse h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = h.IdClient)


		INSERT INTO TEMP_MIG_CLIENTS (IdClientNts,IdSociete,Commentaire,IdSite)
		select distinct(h.IdClient),1,'Quittance' ,h.IdSite
		from NtsAuto_MAMDA.dbo.StdQuittances h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 1
		where s.IdNatureSite = 2 and h.IdSite = @IdSite_
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS where IdSociete = 1 and IdClientNts = h.IdClient)

				
		----- Migration de données Client  MAMDA
		INSERT INTO [dbo].[CLI_Clients]
		([IdSociete],				[IdSource],						[IdSite],					[CodeSite]
		,[Particulier],				[NomClient],					[Nom],						[Prenom1]
		,[CIN],						[DateDelivranceCIN],			[LieuDelivranceCIN],		[Sexe]
		,[VIP],						[IdTypeVIP],					[IdQualite],				[IdSecteur]
		,[IdProfession],				[IdOrganisme],					[DateNaissance],			[IdVilleNaissance]
		,[NumPermis],				[IdTypePermis],					[DateDelivrancePermis],		[IdLieuDelivrancePermis]
		,[DateAccident],				[DateInvalidite],				[NomSociete],				[NomAbrege]
		,[NumIdentificationFiscale],	[NumPatente],					[NumSocietaireHolding],		[NomSocietaireHolding]
		,[NumeroSocietaire],			[AdresseComplete],				[DateCreation]
		,[DateMAJ],					[OperateurCreation],			[OperateurMaj],				[Statut]
		,[TypeAdresse],				[NumeroAdresse],				[IdVoie],					[ComplementAdresseRurale]
		,[CodePostal],				[IdVille],						[IdPays],					[Kiyada]
		,[Douar],					[Province],						[Commune],					[Email]
		,[ComplementAdresseUrbaine],	[Portable],						[Fixe],						[Fax]
		,[Actif],					[IdClientNts],					[Conforme],					[IdOperateurConforme]
		,[DateConforme],			Migre,							DateMigration)
		SELECT						
		1,							NULL,							S.IdSite,					S.CodeSite,
		isnull(C.Particulier,'N'),	C.RaisonSociale,				CASE 
																		WHEN isnull(C.Particulier,'N') = 'O' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		CASE 
			WHEN isnull(C.Particulier,'N') = 'O' THEN CIN_PAT 
			ELSE NULL 
		END,						NULL,							NULL,						NULL,
		isnull(VIP,'N'),			NULL,							Q.IdQualite,			NULL,
		P.IdProfession,				NULL,							CASE 
																		WHEN DateNaissance ='01/01/1900' THEN NULL
																		ELSE DateNaissance
																	END,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						NULL,							CASE 
																		WHEN isnull(C.Particulier,'N') = 'N' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		NULL,						CASE 
										WHEN isnull(C.Particulier,'N') = 'N' THEN CIN_PAT 
										ELSE NULL 
									END,							NULL,						NULL,
		CASE WHEN isnull(C.Matricule,'')='' THEN CAST (C.IdClient as varchar(50)) ELSE C.Matricule END,
				
									C.ADRESSE1 + ' ' +C.ADRESSE2,						C.DateCreation,
		DateMAJ,					U.User_Id,						U.User_Id,					'U',
		'U',						NULL,							NULL,						C.ADRESSE1 + ' ' +C.ADRESSE2,
		NULL,						V.IdVille,						NULL,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP1 like '6%' OR C.TELEP1 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP2 like '6%' OR C.TELEP2 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,					
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.FAX like '6%' OR C.FAX like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,
		NULL,						C.IdClient		,					'N',					NULL,
		NULL,						'O',				@_DateMigration																									
		from NtsAuto_MAMDA.dbo.StdClients C
		INNER JOIN TEMP_MIG_CLIENTS MG 
			on MG.IdClientNts = c.IdClient and MG.IdSociete = 1
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 1
		left join REF_Villes V
			on V.IdVilleNts = C.IdVille and V.IdSociete = 1
		left join REF_Professions P 
			on P.IdProfessionNts = C.IdProfession and P.IdSociete = 1
		left join REF_Qualites Q
			on Q.IdQualiteNts = C.IdQualite and Q.IdSociete = 1
		left join ACL_UsersSites U
			on U.User_Id_Nts = C.IdOperateur and U.Societe_Id = 1 
		where MG.IdSociete = 1 and mg.IdSite = @IdSite_
		and not exists (select IdClient from CLI_Clients where IdClientNts = c.IdClient and IdSociete = 1)


		UPDATE AUTO_Conventions
		set IdSocietaire = CL.IdClient,
			IdSite = CL.IdSite,
			Police = V.Police
		from AUTO_Conventions C
		inner join NtsAuto_Mamda.dbo.OtoConventionsIdt V
			on C.IdConventionW = V.IdConvention and C.IdSociete = 1
		inner join CLI_Clients CL
			on CL.IdClientNts = V.IdSouscripteur and CL.IdSociete = 1

		--- Activation des triggers
		
		ALTER TABLE CLI_Clients ENABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes ENABLE TRIGGER ALL

	-- ======================================================================================
	--					END : Transaction [_MigrerClients]				
	-- ======================================================================================

		
	 RETURN 0

end































GO
-------------------------------------------- RCV_PS_IdentificationClients_ --------------------------------------------
-- exec ps_CPIdentification  
-- Select * from CP_Contentieux where referenceCtx = '371CP201500096'
-- exec  [RCV_IdentificationQuittances] @Souscripteur_ = NULL, @IdEntite_ = NULL, @IdSite_ = 101, @Msg_ = null
CREATE        Procedure [dbo].[RCV_PS_IdentificationClients_]
					@IdClient_          Int          = Null,
					@Assure_            varchar(255) = NULL,				
					@CIN_               varchar(50) = NULL,
					@Souscripteur_      varchar(255) = NULL,
					@Police_            varchar(50) = null,
					@NumQuittance_      varchar(50) = null,
					@IdEntite_          int = null,
					@IdSite_            int = null,
					@IdOperateur_		int
AS
Begin

Declare  @Sql nvarchar(4000), @paramlist nvarchar(4000), @Inner nvarchar(4000),
		 @Condition nvarchar(4000), @Param nvarchar(4000), @Order nvarchar(4000), @Group nvarchar(4000),
		 @Virgule varchar(5), @Pos int, @con varchar(5000),
		 @CodeProfil char(2), @IdSitePartenaire int


Select @Param     = 'Select Distinct C.IdClient , C.NomClient , C.CIN'
Select @Inner     = 'From dbo.RCV_Quittances Q '
--Left JOIN RCV_NatureQuittance NQ ON(NQ.IdNature = Q.IdNature) '
Select @Inner     = @INNER +'INNER JOIN CLI_Clients C ON (C.IdClient = Q.IdSouscripteur)'
Select @Inner     = @INNER +'INNER JOIN dbo.STD_Sites S ON (S.idSite = Q.IdSite)'
Select @Inner     = @INNER +'Left JOIN dbo.RCV_StdStatutQuittance SQ ON (SQ.IdStatut = Q.IdStatut)'


Select @Condition = 'Where 1 = 1 and Encaissee = ''N'''
--select @Group	  = 'Group By D.Contentieux, D.referenceCtx, D.DateSin, D.DateDeclaration, D.Police, C.RaisonSociale, D.SortSin, D.IdSite, D.NomAssure ,PR.Libelle , D.ReferenceExterne'	
Select @Order     = 'Order By C.NomClient '

-- @Souscripteur_
If @Souscripteur_  is not null and @Souscripteur_  <> '' BEGIN
	select @Condition = @Condition + ' AND  C.NomClient like ''%'' + @Souscripteur_ + ''%'' '
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @CIN_
If @CIN_  is not null AND @CIN_  <> '' BEGIN
    select @Condition = @Condition + ' AND  C.CIN like ''%'' + @CIN_ + ''%'' ' 
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @Police_
If @Police_  is not null and @Police_  <> '' BEGIN
	select @Condition = @Condition + ' AND  Q.Police like ''%'' + @Police_ + ''%'' ' 
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @NumQuittance_
If @NumQuittance_  is not null AND @NumQuittance_  <> '' BEGIN
    select @Condition = @Condition + ' AND  Q.NumQuittance like ''%'' + @NumQuittance_ + ''%'' ' 	
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @IdSite_
If @IdSite_  is not null and @IdSite_  <> '' BEGIN
	select @Condition = @Condition + ' AND  Q.IdSite = ' + cast(@IdSite_ as varchar(30))
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

SELECT @CodeProfil = profile_code,
	   @IdSitePartenaire = IdSitePartenaire
FROM ACL_Users u
INNER JOIN ACL_Profiles p
	ON (p.Profile_Id = u.Profile_Id)
WHERE u.User_Id = @IdOperateur_

IF(@CodeProfil = 'PT')
BEGIN
	select @Condition = @Condition + ' AND  C.IdSitePartenaire = ' + cast(@IdSitePartenaire as varchar(30))
	Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
END

-- @IdEntite_
--If @IdEntite_  is not null AND @IdEntite_  <> '' BEGIN
   -- select @Condition = @Condition + ' AND  Q.IdEntite = '	+ cast(@IdEntite_ as varchar(30))
	--Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition
--END


----- Set la requête SQL ------------
Select @Sql = '' + @Param + ' ' + @Inner + ' ' + @Condition + ' ' + ' ' + @Order


SELECT @paramlist = '@Assure_           varchar(255) ,				
					@CIN_			    varchar(50)  ,
					@Souscripteur_      varchar(255) ,
					@Police_            varchar(50)  ,
					@NumQuittance_      varchar(50)  ,
					@IdEntite_          int          ,
					@IdSite_            int          ,
					@IdOperateur_		int			 '		
			
print @sql
 
EXEC sp_executesql @sql, @paramlist,

        @Assure_, @CIN_, @Souscripteur_, @Police_, @NumQuittance_, @IdEntite_, @IdSite_,@IdOperateur_
END

-- exec [ps_CPIdentification] @ReferenceCtx = '371CP201500096'
-- execute ps_CPIdentification @ReferenceCtx = '371CP201500096'
-- exec ps_SinATIdentification @dateSinistreDeb = '10/06/2014',@dateSinistreFin='10/07/2014' 
-- execute ps_SinATIdentification @IdLieuSurvenance= '0',@montantCheque= 27.76
-- execute ps_SinATIdentification @IdLieuSurvenance= '0',@medecinConseil= '0',@avocatConseil= '0',@tribunal= '0',@IdSite_ = -1


GO
-------------------------------------------- MIG_Clients_Courtage --------------------------------------------

CREATE PROCEDURE [dbo].[MIG_Clients_Courtage] 

AS BEGIN
	set nocount on
	set implicit_transactions off

	---------- TABLES UTILISÉES -----------------

		-- NtsAuto.dbo.StdClients
		-- NtsAuto.dbo.StdClients
		-- SI_Migration.dbo.CLI_Clients

	---------------------------------------------
	------------------------------------------
	-- START : DECLARATION DES VARIABLES	   								              
	------------------------------------------
		
		DECLARE	@_CommitVar				Int,  
				@_Msg					Varchar(1000), 
				@_DateMigration			Datetime, 
				@_ProcessMigre			varchar(100),
				@_MotifRejet			varchar(100),
				@_CountClient			int,
				@_CountClientWDIAM		int,
				@_IdSociete				int,
				@_IsRIB					char(1)='N',
				@_RIB					varchar(50),
				@_IdClientMAMDAInsere   int,
				@_IdClientMCMAInsere	int
		
		Declare @_TempClient table(IdCLient int)

		Declare @IdClient_MAMDA int
		Declare @IdClient_MCMA int
		Declare @IdProfession_MAMDA int
		Declare @IdProfession_MCMA int
		Declare @IdProfession int
		Declare @IdVille int
		Declare @Libelle varchar(500)


	------------------------------------------
	-- END : DECLARATION DES VARIABLES	   								              
	------------------------------------------

	------------------------------------------
	-- START : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

		SELECT	@_DateMigration = GetDate()

	------------------------------------------
	-- END : INITIALISATION DES VARIABLES	   								              
	------------------------------------------

	-- ======================================================================================
	--					START : Transaction [_MigrerClients]				
	-- ======================================================================================

		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TEMP_MIG_CLIENTS_COURTAGE]') AND type in (N'U'))
		BEGIN
			CREATE TABLE [dbo].TEMP_MIG_CLIENTS_COURTAGE(
				[IdClientNts] [int] NOT NULL,
				[IdSociete] [int] NOT NULL,
				[Commentaire][varchar] (100) NOT NULL
			) 

			CREATE INDEX indx_Cli_Migr1_C ON TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete);  
			CREATE INDEX indx_Cli_Migr2_C ON TEMP_MIG_CLIENTS_COURTAGE (IdClientNts);
		END
		ELSE BEGIN
			TRUNCATE TABLE TEMP_MIG_CLIENTS_COURTAGE
		END
		-----------------------------------------------------------------------------------------------
		---									INSERTION CLIENTS MCMA
		-----------------------------------------------------------------------------------------------


		--- Désactivation des triggers
		
		ALTER TABLE CLI_Clients DISABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes DISABLE TRIGGER ALL

		--------------------------------------------------

		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		SELECT    IdClient,3,'Client'
		FROM NtsAuto.dbo.StdClients C
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 3
		where s.IdNatureSite = 1  
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = C.IdClient) 
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = C.IdClient) 
		

		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3 , 'Historique_Client'
		from NtsAuto.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite =1
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = h.IdClient) 
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = h.IdClient) 
		and REF_AGENT not like '%MIG_SIN%'


		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdAssure),3 ,'Historique_Assure'
		from NtsAuto.dbo.OtoHistorique h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite =1
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = h.IdAssure) 
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = h.IdAssure) 
		and REF_AGENT not like '%MIG_SIN%'

		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3 ,'RDPolice_Client'
		from NtsAuto.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite =1 and h.IdProduit <>33
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = h.IdClient) 
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = h.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdASSURE),3 ,'RDPolice_Assure'
		from NtsAuto.dbo.RdPolices h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite =1 and h.IdProduit <>33
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = h.IdASSURE)
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = h.IdASSURE) 

		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3 ,'Encaissement'
		from NtsAuto.dbo.StdIEncaisse h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite =1 
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = h.IdClient)
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = h.IdClient) 

		INSERT INTO TEMP_MIG_CLIENTS_COURTAGE (IdClientNts,IdSociete,Commentaire)
		select distinct(h.IdClient),3,'Quittance' 
		from NtsAuto.dbo.StdQuittances h
		inner join STD_Sites S
			on S.IdSiteNts = H.IdSite and S.IdSociete = 3
		where s.IdNatureSite =1
		and not exists (select IdClientNts from TEMP_MIG_CLIENTS_COURTAGE where IdSociete = 3 and IdClientNts = h.IdClient)
		and not exists (select IdClientNts from CLI_Clients where IdSociete = 3 and IdClientNts = h.IdClient) 

				
		------- Migration de données Client  MCMA
		INSERT INTO [dbo].[CLI_Clients]
		([IdSociete],				[IdSource],						[IdSite],					[CodeSite]
		,[Particulier],				[NomClient],					[Nom],						[Prenom1]
		,[CIN],						[DateDelivranceCIN],			[LieuDelivranceCIN],		[Sexe]
		,[VIP],						[IdTypeVIP],					[IdQualite],				[IdSecteur]
		,[IdProfession],				[IdOrganisme],					[DateNaissance],			[IdVilleNaissance]
		,[NumPermis],				[IdTypePermis],					[DateDelivrancePermis],		[IdLieuDelivrancePermis]
		,[DateAccident],				[DateInvalidite],				[NomSociete],				[NomAbrege]
		,[NumIdentificationFiscale],	[NumPatente],					[NumSocietaireHolding],		[NomSocietaireHolding]
		,[NumeroSocietaire],			[AdresseComplete],				[DateCreation]
		,[DateMAJ],					[OperateurCreation],			[OperateurMaj],				[Statut]
		,[TypeAdresse],				[NumeroAdresse],				[IdVoie],					[ComplementAdresseRurale]
		,[CodePostal],				[IdVille],						[IdPays],					[Kiyada]
		,[Douar],					[Province],						[Commune],					[Email]
		,[ComplementAdresseUrbaine],	[Portable],						[Fixe],						[Fax]
		,[Actif],					[IdClientNts],					[Conforme],					[IdOperateurConforme]
		,[DateConforme],			migre,							DateMigration)
		SELECT						
		3,							NULL,							S.IdSite,					S.CodeSite,
		isnull(C.Particulier,'N'),	C.RaisonSociale,				CASE 
																		WHEN isnull(C.Particulier,'N') = 'O' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		CASE 
			WHEN isnull(C.Particulier,'N') = 'O' THEN CIN_PAT 
			ELSE NULL 
		END,						NULL,							NULL,						NULL,
		isnull(VIP,'N'),			NULL,							Q.IdQualite,			NULL,
		P.IdProfession,				NULL,							CASE 
																		WHEN DateNaissance ='01/01/1900' THEN NULL
																		ELSE DateNaissance
																	END,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						NULL,							CASE 
																		WHEN isnull(C.Particulier,'N') = 'N' THEN C.RAISONSOCIALE
																		ELSE NULL 
																	END,						NULL,
		NULL,						CASE 
										WHEN isnull(C.Particulier,'N') = 'N' THEN CIN_PAT 
										ELSE NULL 
									END,							NULL,						NULL,
		CASE WHEN isnull(C.Matricule,'')='' THEN CAST (C.IdClient as varchar(50)) ELSE C.Matricule END,
				
									C.ADRESSE1 + ' ' +C.ADRESSE2,						C.DateCreation,
		DateMAJ,					U.User_Id,						U.User_Id,					'U',
		'U',						NULL,							NULL,						C.ADRESSE1 + ' ' +C.ADRESSE2,
		NULL,						V.IdVille,						NULL,						NULL,
		NULL,						NULL,							NULL,						NULL,
		NULL,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP1 like '6%' OR C.TELEP1 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep1,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,						
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.TELEP2 like '6%' OR C.TELEP2 like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Telep2,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,					
		CASE 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 8 
			THEN '06'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN len(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.FAX,'+212','0'),'.',''),'*',''),' ',''),'-','')) = 9
			AND (C.FAX like '6%' OR C.FAX like '5%')
			THEN '0'+REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
			WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') in ('0','06','05')
			THEN '' 
			ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(C.Fax,'+212','0'),'.',''),'*',''),' ',''),'-','') 
		END,
		NULL,						C.IdClient		,					'N',					NULL,
		NULL,						'O',		@_DateMigration																									
		from NtsAuto.dbo.StdClients C
		INNER JOIN TEMP_MIG_CLIENTS_COURTAGE MG 
			on MG.IdClientNts = c.IdClient and MG.IdSociete = 3
		inner join STD_Sites S
			on S.IdSiteNts = C.IdSite and S.IdSociete = 3
		left join REF_Villes V
			on V.IdVilleNts = C.IdVille and V.IdSociete = 3
		left join REF_Professions P 
			on P.IdProfessionNts = C.IdProfession and P.IdSociete = 3
		left join REF_Qualites Q
			on Q.IdQualiteNts = C.IdQualite and Q.IdSociete = 3
		left join ACL_UsersSites U
			on U.User_Id_Nts = C.IdOperateur and U.Societe_Id = 3
		where MG.IdSociete = 3
		and not exists (select CLI.IdClient from CLI_Clients CLI where CLI.IdClientNts = C.IdClient and CLI.IdSociete = 3)


		--- Activation des triggers
		
		ALTER TABLE CLI_Clients ENABLE TRIGGER ALL
		ALTER TABLE CLI_Comptes ENABLE TRIGGER ALL

	-- ======================================================================================
	--					END : Transaction [_MigrerClients]				
	-- ======================================================================================

		
	 RETURN 0

end































GO
