
/*�ر�˵�����ṩ���ַ��ط�ʽ��  
�������ݼ���������.net������ʽ��������Ҫ�����洢���̰�װ������usp_myProjFilterBaseDT  
�����α꣬�����ڴ洢����ֱ�ӷ��ʽ����������usp_myContractFilter  
ԭ�򣺴洢���̲�����inert into execǶ��ʹ�ã�.net���ܵ��ô��α�����Ĵ洢����  
*/  
  
--���ܣ���ȡ�û�����Ŀ���˽����  
--������  
--  @chvUserGUID  ��ǰ�û���GUID  
--  @chvApplication  Ӧ��ϵͳ����  
--  @chvBUGUID   ��˾GUID�����Ϊ���򲻼ӹ�˾����  
--  @blnisUserFilter �Ƿ�����û��Լ��������Ŀ����  
--  @chvResultType  �������͡���table�����������ݼ�������cursor���������α꣩  
--  @curResult   ���ص��α�  
ALTER   PROCEDURE [dbo].[usp_myProjFilterBase]  
    (  
      @chvUserGUID NVARCHAR(40) ,  
      @chvApplication NVARCHAR(16) = '0101' ,  
      @chvBUGUID NVARCHAR(40) = '' ,  
      @blnisUserFilter BIT = 1 ,  
      @chvResultType VARCHAR(10) = 'table' ,  
      @curResult CURSOR VARYING OUTPUT  
   
    )  
AS 
IF @chvBUGUID<>''
BEGIN  
SELECT @chvBUGUID='' FROM dbo.myBusinessUnit WHERE BUGUID=@chvBUGUID
AND ParentGUID IS NULL
END

    SET NOCOUNT ON  

    IF @chvApplication IS NULL   
        SET @chvApplication = '0101'  
    IF @chvBUGUID IS NULL   
        SET @chvBUGUID = ''  
    IF @blnisUserFilter IS NULL   
        SET @blnisUserFilter = 1  
  
    SET @chvUserGUID = REPLACE(@chvUserGUID, '''', '''''')              
    SET @chvApplication = REPLACE(@chvApplication, '''', '''''')              
 --SET @chvErrorInfo = ''  
  
 --1����ȡԭʼ����ĿȨ�޼���  
 --#dtAllObject �������ݶ���  
 --#dtUO   ��ǰ�û����е����ݶ���Ȩ��  
   
    DECLARE @chvSQL VARCHAR(8000) ,  
        @chvFilt VARCHAR(MAX) ,  
        @bIsAdmin BIT              
  
   
    --������Ȩ������  
    DECLARE @chvXML NVARCHAR(4000) ,  
        @hDoc INT ,  
        @chvXPath VARCHAR(200) ,  
        @chvDataType VARCHAR(50) ,  
        @chvDataSource VARCHAR(8000)   
   
    EXEC usp_myGetDataRightsXML @chvXML OUTPUT  
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @chvXML  
   
    SET @chvXPath = '//object[@id=''project'']'   
  
    SELECT  @chvDataType = UPPER(datatype) ,  
            @chvDataSource = datasource  
    FROM    OPENXML (@hDoc,@chvXPath ,1)  
    WITH ( datatype VARCHAR(50) 'datatype',  
      datasource VARCHAR(8000) 'datasource' )  
    
    IF @@ROWCOUNT = 0   
        BEGIN  
   --SET @chvErrorInfo = 'idΪ��project�������ݶ���û�ж��壡'  
            GOTO RETURN_NULL  
        END  
  
    --��ȡ����Դ��Ŀǰֻ֧�� SQL  
    IF @chvDataType = 'SQL'   
        BEGIN  
            SET @chvDataSource = @chvDataSource  
        END  
    ELSE   
        BEGIN  
   --SET @chvErrorInfo = 'idΪ��project�������ݶ��������'  
            GOTO RETURN_NULL  
        END  
    
 --����#dtAllObject���������ݶ�����ʱ��  
    CREATE TABLE #dtAllObject  
        (  
          _guid UNIQUEIDENTIFIER ,  
          _name VARCHAR(1000) ,  
          _hierarchycode VARCHAR(1000) ,  
          _sourcetype VARCHAR(100) ,  
          _level INT ,  
          _buguid VARCHAR(40) ,  
          _isshare INT ,  

          _isallowopr VARCHAR(1) DEFAULT '0'  
        )  
   
 --�洢�������޷�ʵʱ�޸ı�ṹ   
    INSERT  INTO #dtAllObject  
            ( _guid ,  
              _name ,  
              _hierarchycode ,  
              _sourcetype ,  
              _level ,  
              _buguid ,  
              _isshare  
            )  
            EXEC ( @chvDataSource  
                )  
   
    SELECT  @bIsAdmin = IsAdmin  
    FROM    myUser  
    WHERE   UserGUID = @chvUserGUID --�Ƿ����Ա��1���ǡ�0����   
  
  
 --�����û���Ȩ�޽��й���  
    IF @bIsAdmin = 1   
        BEGIN  
   --����Ա��ӵ�����е�����Ȩ��  
            UPDATE  #dtAllObject  
            SET     _isallowopr = 1   
        END  
    ELSE   
        BEGIN  
   --��ͨ�û���ֻ�������е�����Ȩ��     
            SELECT  *  
            INTO    #dtUO  
            FROM    (   
    --SELECT a.UserGUID,a.StationGUID,b.ObjectType,b.ObjectGUID,b.TableName,b.BUGUID,c._hierarchycode  
                      SELECT DISTINCT  
                                c._hierarchycode  
                      FROM      myStationUser a  
                                INNER JOIN myStationObject b ON a.stationguid = b.stationguid  
                                INNER JOIN #dtAllObject c ON c._guid = b.ObjectGUID  
                                                             AND c._buguid = b.BUGUID  
                      WHERE     ObjectType = 'project'  
                                AND UserGUID = @chvUserGUID  
                    ) a  
     
            IF @@ROWCOUNT > 0    --myUserObject���ܴ�����������  
                BEGIN  
     --�������¼�  
                    UPDATE  a  
                    SET     a._isallowopr = 1  
                    FROM    #dtAllObject a  
                            INNER JOIN #dtUO b ON a._hierarchycode + '.' LIKE b._hierarchycode  
                                                  + '.%'  
                END     
      
            DROP TABLE #dtUO     
        END  
  

   --����DataRightsDTType���ͽ��й���  
    SET @chvFilt = ''  
	
	Create table #tmpBUGUID
	(
		BUGUID UNIQUEIDENTIFIER 
	)

    IF @bIsAdmin = 1  
        --����ǹ���Ա��ֻ���û�������˾�� Deep Ȩ�ޣ�������DataRightsDTType��  
        BEGIN  
            Insert Into #tmpBUGUID(BUGUID)
            SELECT    BUGUID  
                      FROM      myBusinessUnit  
                      WHERE     CHARINDEX(( SELECT  HierarchyCode + '.'  
                                            FROM    myBusinessUnit  
                                            WHERE   BUGUID = ( SELECT  
                                                              BUGUID  
                                                              FROM  
                                                              myUser  
                                                              WHERE  
                                                              UserGUID = ''  
                                                              + @chvUserGUID  
                                                              + ''  
                                                             )  
                                          ), HierarchyCode + '.') = 1  
            /*  
            DECLARE @guid VARCHAR(MAX)  
            SET @guid = ''''  
            SELECT  @guid = @guid + CONVERT(VARCHAR(40), a.BUGUID) + ''','''  
            FROM    ( SELECT    BUGUID  
                      FROM      myBusinessUnit  
                      WHERE     CHARINDEX(( SELECT  HierarchyCode + '.'  
                                            FROM    myBusinessUnit  
                                            WHERE   BUGUID = ( SELECT  
                                                              BUGUID  
                                                              FROM  
                                                              myUser  
                                                              WHERE  
                                                              UserGUID = ''  
                                                              + @chvUserGUID  
                                                              + ''  
                                                             )  
                                          ), HierarchyCode + '.') = 1  
                    ) AS a           
                      
            IF LEN(@guid) >= 2   
                SELECT  @guid = SUBSTRING(@guid, 1, LEN(@guid) - 2)        
            ELSE  
				--���һ��GUID,���ⱨ��  
                SET @guid = '''A9FB9CB3-5A7C-41F9-8518-31494E56243C'''   
			
			--����ǹ���Ա��ֻ���û�������˾�� Deep Ȩ�ޣ�������DataRightsDTType��  
            SET @chvFilt = '_buguid not in (' + @guid + ')'  
            */
            SET @chvFilt ='_buguid not in(SELECT BUGUID FROM #tmpBUGUID)'
        END  
    ELSE   
        BEGIN   
            SET @chvFilt = '_isallowopr = ''0'''  
        END  
 
 --����ǿͷ�ϵͳ(0102)����Ҫ���˵�������Ŀ����      
    IF @chvApplication <> ''  
        AND @chvApplication <> '0102'   
        SET @chvFilt = @chvFilt + ' OR _isshare=1'   
   
 --�����������͹���  
   SET @chvFilt = @chvFilt + ' OR _sourcetype <> ''��Ŀ'''  
  
	--ɾ���������������˵ļ�¼ 
	SET @chvSQL = 'DELETE #dtAllObject WHERE ' + @chvFilt  
    
    EXEC (@chvSQL)  
   
 --2����ԭʼ����ĿȨ�޼��Ͻ��й���  
 --�ӹ�˾����  
    IF @chvBUGUID <> ''   
        DELETE  #dtAllObject  
        WHERE _buguid NOT IN (SELECT BUGUID FROM dbo.myBusinessUnit WHERE ParentGUID =@chvBUGUID OR BUGUID =@chvBUGUID)
  
    SELECT  _guid AS ProjGUID ,  
            _buguid AS BUGUID  
    INTO    #dtDataRights  
    FROM    #dtAllObject   
    
    
    IF @@ROWCOUNT = 0   
        GOTO RETURN_NULL  
  
    SELECT  *  
    INTO    #Temp  
    FROM    #dtDataRights  
    WHERE   1 = 2   
    
    
 --������õġ���Ŀ��ϵͳ���ˡ�������Ҫ���˵�ǰϵͳ�����õ���Ŀ  
    IF EXISTS ( SELECT  1  
                FROM    myApplication  
                WHERE   ISNULL(IsApplySys, 0) = 1  
                        AND Application = @chvApplication )   
        BEGIN  
            IF @chvApplication = '0102'   
                BEGIN  
                    IF @chvBUGUID = ''   
                        INSERT  INTO #Temp  
                                SELECT  a.*  
                                FROM    #dtDataRights a  
                                        INNER JOIN ( SELECT ProjGUID ,  
                                                            BUGUID  
                                                     FROM   ek_Project  
                                                     WHERE  CHARINDEX(','  
                                                              + @chvApplication  
                                                              + ',',  
                                                              ',' + ApplySys  
                                                              + ',') > 0  
                       ) b ON a.ProjGUID = b.ProjGUID  
                                                          AND a.BUGUID = b.BUGUID  
                    ELSE
                        INSERT  INTO #Temp  
                                SELECT  a.*  
                                FROM    #dtDataRights a  
                                        INNER JOIN ( SELECT ProjGUID ,  
                                                            BUGUID  
                                                     FROM   ek_Project  
                                                     WHERE  CHARINDEX(','  
                                                              + @chvApplication  
                                                              + ',',  
                                                              ',' + ApplySys  
                                                              + ',') > 0  
                                                            AND BUGUID IN (SELECT BUGUID FROM dbo.e_myBusinessUnit WHERE ParentGUID =@chvBUGUID OR BUGUID = @chvBUGUID)
                                                   ) b ON a.ProjGUID = b.ProjGUID  
                                                          AND a.BUGUID = b.BUGUID  
  
  
                    DELETE  FROM #dtDataRights  
                    INSERT  INTO #dtDataRights  
                            SELECT  *  
                            FROM    #Temp  
                    TRUNCATE TABLE #Temp  
                    
                END  
      
            ELSE   
                BEGIN  
                    IF @chvBUGUID = ''   
                        INSERT  INTO #Temp  
                                SELECT  a.*  
                                FROM    #dtDataRights a  
                                        INNER JOIN ( SELECT ProjGUID ,  
                                                            BUGUID  
                                                     FROM   ep_Project  
                                                     WHERE  CHARINDEX(','  
                                                              + @chvApplication  
                                                              + ',',  
                                                              ',' + ApplySys  
                                                              + ',') > 0  
                                                   ) b ON a.ProjGUID = b.ProjGUID  
                                                          AND a.BUGUID = b.BUGUID  
                    ELSE   
                    
                        INSERT  INTO #Temp  
                                SELECT  a.*  
                                FROM    #dtDataRights a  
                                        INNER JOIN ( SELECT ProjGUID ,  
                                                            BUGUID  
                                                     FROM   ep_Project  
                                                     WHERE  CHARINDEX(','  
                                                              + @chvApplication  
                                                              + ',',  
                                                              ',' + ApplySys  
                                                              + ',') > 0  
                                                            AND BUGUID IN (SELECT BUGUID FROM dbo.e_myBusinessUnit WHERE ParentGUID =@chvBUGUID OR BUGUID = @chvBUGUID)
                                                   ) b ON a.ProjGUID = b.ProjGUID  
                                                          AND a.BUGUID = b.BUGUID  
  
                    DELETE  FROM #dtDataRights  
                    INSERT  INTO #dtDataRights  
                            SELECT  *  
                            FROM    #Temp  
                    TRUNCATE TABLE #Temp  
                END  
        END  
   
   
 --�����û��Լ��������Ŀ����  
    IF @blnisUserFilter = 1  
        AND EXISTS ( SELECT 1  
                     FROM   myUser  
                     WHERE  ISNULL(UserProject, '') <> '[ALL]'  
                            AND UserGUID = @chvUserGUID )   
        BEGIN  
            IF @chvBUGUID = ''   
                INSERT  INTO #Temp  
        SELECT  a.*  
                        FROM    #dtDataRights a  
                                INNER JOIN ( SELECT ProjGUID ,  
                                                    BUGUID  
                                             FROM   myUserProject  
                                             WHERE  UserGUID = @chvUserGUID  
                                           ) b ON a.ProjGUID = b.ProjGUID  
                                                  AND a.BUGUID = b.BUGUID  
            ELSE   
                INSERT  INTO #Temp  
                        SELECT  a.*  
                        FROM    #dtDataRights a  
                                INNER JOIN ( SELECT ProjGUID ,  
                                                    BUGUID  
                                             FROM   myUserProject  
                                             WHERE  UserGUID = @chvUserGUID  
                                                   AND BUGUID IN (SELECT BUGUID FROM dbo.e_myBusinessUnit WHERE ParentGUID =@chvBUGUID OR BUGUID = @chvBUGUID)
                                           ) b ON a.ProjGUID = b.ProjGUID  
                                                  AND a.BUGUID = b.BUGUID  
     
            DELETE  FROM #dtDataRights  
            INSERT  INTO #dtDataRights  
                    SELECT  *  
                    FROM    #Temp  
            TRUNCATE TABLE #Temp  
        END  
  
  
 --�ɹ�:��������  
    DROP TABLE #Temp  
    EXEC sp_xml_removedocument @hDoc  
  
    SET NOCOUNT OFF  
    IF @chvResultType = 'table'   
        BEGIN  
   --���ؽ����  
            SELECT  ProjGUID  
            FROM    #dtDataRights  
        END  
    ELSE   
        BEGIN  
   --����α�  
            SET @curResult = CURSOR FORWARD_ONLY STATIC FOR   
    SELECT ProjGUID FROM #dtDataRights  
            OPEN @curResult  
        END  
    RETURN 1  
   
 --ʧ��:���ؿ����ݼ�  
    RETURN_NULL:  
    IF NOT OBJECT_ID('tempdb..#b') IS NULL   
        DROP TABLE #Temp  
  
    EXEC sp_xml_removedocument @hDoc  
  
    SET NOCOUNT OFF  
    IF @chvResultType = 'table'   
        BEGIN  
   --���ؽ����  
            SELECT  NULL AS ProjGUID  
            WHERE   1 = 2  
        END  
    ELSE   
        BEGIN  
   --����α�  
            SET @curResult = CURSOR FORWARD_ONLY STATIC FOR   
    SELECT NULL AS ProjGUID WHERE 1=2  
            OPEN @curResult  
        END  
    RETURN 0


GO
