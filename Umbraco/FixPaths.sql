/*
 Symptom: X can not be published, because a parent page is not published.
 Resolution: If this query returns any rows, the path requires updating using the SQL returned in the final column (UpdateStatement)
 Caution: Use the update statements at your own risk!
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

IF EXISTS (SELECT TOP 1 1 FROM umbracoNode WHERE [path] NOT LIKE '%'+  LTRIM(RTRIM(str(id))))
BEGIN
	;WITH nodes AS (
		SELECT n.Id, 
			d.[text] AS NodeName, 
			n.parentID,
			CAST(ROW_NUMBER() OVER (ORDER BY n.Id) AS VARCHAR(MAX)) AS idx, 
			0 AS lvl,
			d.versionId,
			n.path,
			CONVERT(NVARCHAR(20), n.parentID) + ',' + CONVERT(NVARCHAR(20), n.id) AS newPath
		FROM cmsDocument d
		INNER JOIN umbracoNode n
			ON d.nodeId = n.id
		INNER JOIN (
			SELECT nodeId, MAX(updateDate) AS updateDate
			FROM cmsDocument 
			GROUP BY nodeId
		)u
			ON d.nodeId = u.nodeId
			AND d.updateDate = u.updateDate
		WHERE n.parentID = -1
		UNION ALL
		SELECT  n.Id, 
			d.[text], 
			n.parentID, 
			nodes.idx + '.' + CASE WHEN ROW_NUMBER() OVER (PARTITION BY n.ParentID ORDER BY n.Id) <= 9 THEN '0' ELSE '' END + CAST(ROW_NUMBER() OVER (PARTITION BY n.ParentID ORDER BY n.Id) AS VARCHAR(MAX)), 
			nodes.lvl + 1,
			d.versionId,
			n.[path],
			CONVERT(NVARCHAR(20), newPath) + ',' + CONVERT(NVARCHAR(20), n.id)
		FROM cmsDocument d
		INNER JOIN umbracoNode n
			ON d.nodeId = n.id
		JOIN nodes 
			ON n.parentId = nodes.id
		WHERE newest = 1
	)
	SELECT *, 'UPDATE umbracoNode SET path = ''' + newPath + ''' WHERE id = ' + CONVERT(NVARCHAR(30), id) AS UpdateStatement
	FROM nodes
	WHERE path NOT LIKE '%'+  LTRIM(RTRIM(str(id)))
END
ELSE
	RAISERROR('No problems with node paths detected.', 10, 1)