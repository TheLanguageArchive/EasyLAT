<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:foxml="info:fedora/fedora-system:def/foxml#" xmlns:cmd="http://www.clarin.eu/cmd/" xmlns:lat="http://lat.mpi.nl/" xmlns:sx="java:nl.mpi.tla.saxon" exclude-result-prefixes="xs sx lat" version="2.0">

	<xsl:variable name="rec" select="/"/>

	<xsl:param name="rels-uri" select="'./relations.xml'"/>
	<xsl:param name="rels-doc" select="document($rels-uri)"/>
	<xsl:key name="rels-from" match="relation" use="src | from"/>
	<xsl:key name="rels-to" match="relation" use="dst | to"/>

	<xsl:param name="conversion-base" select="()"/>
	<xsl:param name="import-base" select="()"/>
	<xsl:param name="fox-base" select="'./fox'"/>
	<xsl:param name="lax-resource-check" select="false()"/>

	<xsl:param name="repository" select="'flat.example.com'"/>

	<xsl:param name="create-cmd-object" select="true()"/>

	<xsl:param name="collections-map">
		<map/>
	</xsl:param>
	
	<xsl:param name="oai-include-eval" select="'true()'"/>
	
	<xsl:variable name="namespaces">
		<ns/>
	</xsl:variable>
	<xsl:variable name="NS" select="$namespaces/descendant-or-self::ns"/>
	
	<xsl:param name="icon-base" select="'/app/flat/icons'"/>

	<xsl:function name="cmd:hdl">
		<xsl:param name="pid"/>
		<xsl:sequence select="replace(replace($pid, '^http://hdl.handle.net/', 'hdl:'), '@format=[a-z]+', '')"/>
	</xsl:function>

	<xsl:function name="cmd:lat">
		<xsl:param name="prefix"/>
		<xsl:param name="pid"/>
		<xsl:variable name="suffix" select="replace(replace(cmd:hdl($pid), '[^a-zA-Z0-9]', '_'), '^hdl_', '')"/>
		<xsl:variable name="length" select="
				min((string-length($suffix),
				(64 - string-length($prefix))))"/>
		<xsl:sequence select="concat($prefix, substring($suffix, string-length($suffix) - $length + 1))"/>
	</xsl:function>

	<xsl:function name="cmd:pid">
		<xsl:param name="locs"/>
		<xsl:param name="lvl"/>
		<xsl:choose>
			<xsl:when test="empty($rels-doc/relations/relation)">
				<xsl:sequence select="cmd:hdl($locs[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="to" select="
					$rels-doc/key('rels-to', for $l in $locs
					return
					cmd:hdl($l))"/>
				<xsl:variable name="from" select="
					$rels-doc/key('rels-from', for $l in $locs
					return
					cmd:hdl($l))"/>
				<xsl:variable name="refs" select="
					distinct-values(($from/src,
					$from/from,
					$to/dst,
					$to/to))[normalize-space(.) != '']"/>
				<xsl:variable name="hdl" select="$refs[starts-with(., 'hdl:')]"/>
				<xsl:choose>
					<xsl:when test="count($hdl) eq 0">
						<xsl:message>
							<xsl:value-of select="$lvl"/>
							<xsl:text>: the handle for resource[</xsl:text>
							<xsl:value-of select="
								string-join(distinct-values(for $l in $locs
								return
								cmd:hdl($l)), ', ')"/>
							<xsl:text>][</xsl:text>
							<xsl:value-of select="string-join($refs, ', ')"/>
							<xsl:text>] can't be determined!</xsl:text>
						</xsl:message>
						<xsl:sequence select="()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="count($hdl) gt 1">
							<xsl:message>
								<xsl:text>ERR: there are multiple handles[</xsl:text>
								<xsl:value-of select="string-join($hdl, ', ')"/>
								<xsl:text>] for resource[</xsl:text>
								<xsl:value-of select="
									string-join(distinct-values(for $l in $locs
									return
									cmd:hdl($l)), ', ')"/>
								<xsl:text>][</xsl:text>
								<xsl:value-of select="string-join($refs, ', ')"/>
								<xsl:text>]! Using the first one ...</xsl:text>
							</xsl:message>
						</xsl:if>
						<xsl:sequence select="cmd:hdl(($hdl)[1])"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="cmd:pid">
		<xsl:param name="locs"/>
		<xsl:sequence select="cmd:pid($locs, 'ERR')"/>
	</xsl:function>

	<xsl:function name="cmd:collections" as="xs:string*">
		<!--<xsl:sequence select="for $xp in $collections-map//xpath return if (sx:evaluate($rec,$xp,$collections-map/descendant-or-self::map)) then ($xp/parent::collection/@pid) else ()" as="xs:string*"/>-->
		<xsl:variable name="collections" as="xs:string*">
			<xsl:for-each select="$collections-map//xpath">
				<xsl:variable name="xp" select="current()"/>
				<xsl:choose>
					<xsl:when test="sx:evaluate($rec, $xp, $collections-map/descendant-or-self::map)">
						<!--<xsl:message>
							<xsl:text>XPath[</xsl:text>
							<xsl:value-of select="$xp"/>
							<xsl:text>][</xsl:text>
							<xsl:value-of
								select="sx:evaluate($rec, $xp, $collections-map/descendant-or-self::map)"/>
							<xsl:text>] matches!</xsl:text>
						</xsl:message>-->
						<xsl:sequence select="$xp/parent::collection/@pid"/>
					</xsl:when>
					<xsl:otherwise>
						<!--<xsl:message>
							<xsl:text>XPath[</xsl:text>
							<xsl:value-of select="$xp"/>
							<xsl:text>][</xsl:text>
							<xsl:value-of
								select="sx:evaluate($rec, $xp, $collections-map/descendant-or-self::map)"/>
							<xsl:text>] doesn't match!</xsl:text>
						</xsl:message>-->
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="(count($collections) gt 1) and ($collections-map/descendant-or-self::map/@mode = 'first')">
				<xsl:sequence select="($collections)[1]"/>
			</xsl:when>
			<xsl:when test="(count($collections) eq 0) and exists($collections-map/descendant-or-self::map/@default)">
				<xsl:sequence select="$collections-map/descendant-or-self::map/@default"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$collections"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:template match="/">
		<xsl:variable name="base" select="base-uri()"/>
		<xsl:variable name="self" select="normalize-space($rec/cmd:CMD/cmd:Header/cmd:MdSelfLink)"/>
		<xsl:variable name="pid">
			<xsl:choose>
				<xsl:when test="normalize-space($rec/cmd:CMD/cmd:Header/cmd:MdSelfLink) = ''">
					<xsl:message>
						<xsl:text>ERR: CMD record[</xsl:text>
						<xsl:value-of select="$base"/>
						<xsl:text>] has no or empty MdSelfLink!</xsl:text>
					</xsl:message>
					<xsl:variable name="hdl" select="cmd:pid($base)"/>
					<xsl:choose>
						<xsl:when test="normalize-space($hdl) != ''">
							<xsl:message>
								<xsl:text>WRN: found handle[</xsl:text>
								<xsl:value-of select="$hdl"/>
								<xsl:text>] for CMD record[</xsl:text>
								<xsl:value-of select="$base"/>
								<xsl:text>]</xsl:text>
							</xsl:message>
							<xsl:sequence select="$hdl"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:message>WRN: using base URI instead.</xsl:message>
							<xsl:sequence select="$base"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="starts-with(cmd:hdl($rec/cmd:CMD/cmd:Header/cmd:MdSelfLink), 'hdl:')">
					<xsl:sequence select="cmd:hdl($rec/cmd:CMD/cmd:Header/cmd:MdSelfLink)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:sequence select="normalize-space($rec/cmd:CMD/cmd:Header/cmd:MdSelfLink)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="fid" select="cmd:lat('lat:', $pid)"/>
		<xsl:message>
			<xsl:text>DBG: CMDI2FOX[</xsl:text>
			<xsl:value-of select="$pid"/>
			<xsl:text>][</xsl:text>
			<xsl:value-of select="$fid"/>
			<xsl:text>][</xsl:text>
			<xsl:value-of select="$base"/>
			<xsl:text>]</xsl:text>
		</xsl:message>
		<!--<xsl:message>DBG: [<xsl:value-of select="$rels-doc/key('rels-from',$pid)[1]/src"/>]!=[<xsl:value-of select="base-uri()"/>] => [<xsl:value-of select="$rels-doc/key('rels-from',$pid)[1]/src!=base-uri()"/>]</xsl:message>-->
		<xsl:if test="$rels-doc/key('rels-from', $pid)[1]/src != $base">
			<xsl:message>
				<xsl:text>ERR: record[</xsl:text>
				<xsl:value-of select="$base"/>
				<xsl:text>] has an already used PID URI[</xsl:text>
				<xsl:value-of select="$pid"/>
				<xsl:text>][</xsl:text>
				<xsl:value-of select="(key('rels-from', $pid))[1]/src"/>
				<xsl:text>]!</xsl:text>
			</xsl:message>
			<xsl:message terminate="yes">
				<xsl:text>WRN: resource FOX[</xsl:text>
				<xsl:value-of select="$fid"/>
				<xsl:text>] will not be created!</xsl:text>
			</xsl:message>
		</xsl:if>
		<xsl:variable name="dc">
			<xsl:apply-templates mode="dc"/>
		</xsl:variable>
		<!--<xsl:message>DBG: look for parents (rels-to:dst|to) of [<xsl:value-of select="$pid"/>] or [<xsl:value-of select="$base"/>] </xsl:message>-->
		<xsl:variable name="parents" select="
				distinct-values($rels-doc/key('rels-to', ($pid,
				$base))[type = 'Metadata']/from)"/>
		<!--<xsl:message>DBG: parents[<xsl:value-of select="string-join($parents,', ')"/>] </xsl:message>-->
		<xsl:variable name="collections" select="cmd:collections()"/>
		<foxml:digitalObject VERSION="1.1" PID="{$fid}" xmlns:xsii="http://www.w3.org/2001/XMLSchema-instance" xsii:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
			<xsl:comment>
				<xsl:text>Source: </xsl:text>
				<xsl:value-of select="base-uri()"/>
			</xsl:comment>
			<foxml:objectProperties>
				<!-- [A]ctive state -->
				<foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="A"/>
				<!-- take the first title found in the Dublin Core -->
				<foxml:property NAME="info:fedora/fedora-system:def/model#label">
					<xsl:variable name="label" select="($dc//dc:title[normalize-space() != ''])[1]" xmlns:dc="http://purl.org/dc/elements/1.1/"/>
					<xsl:choose>
						<xsl:when test="exists($label)">
							<xsl:attribute name="VALUE" select="substring($label, 1, 255)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="VALUE" select="$pid"/>
						</xsl:otherwise>
					</xsl:choose>
				</foxml:property>
			</foxml:objectProperties>
			<!-- Metadata: Dublin Core -->
			<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="DC" STATE="A" CONTROL_GROUP="X">
				<foxml:datastreamVersion ID="DC.0" FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" MIMETYPE="text/xml" LABEL="Dublin Core Record for this object">
					<foxml:xmlContent>
						<xsl:copy-of select="$dc"/>
					</foxml:xmlContent>
				</foxml:datastreamVersion>
			</foxml:datastream>
			<!-- Metadata: CMD -->
			<xsl:choose>
				<xsl:when test="$create-cmd-object">
					<xsl:variable name="cmdID" select="cmd:lat('lat:', concat($pid, '-CMD'))"/>
					<xsl:variable name="cmdFOX" select="concat($fox-base, '/', replace($cmdID, '[^a-zA-Z0-9]', '_'), '.xml')"/>
					<xsl:choose>
						<xsl:when test="not(doc-available($cmdFOX))">
							<xsl:message>DBG: creating CMD FOX[<xsl:value-of select="$cmdFOX"/>]</xsl:message>
							<xsl:result-document href="{$cmdFOX}">
								<foxml:digitalObject VERSION="1.1" PID="{$cmdID}" xmlns:xsii="http://www.w3.org/2001/XMLSchema-instance" xsii:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
									<xsl:comment>
									<xsl:text>Source: </xsl:text>
									<xsl:value-of select="base-uri()"/>
								</xsl:comment>
									<foxml:objectProperties>
										<!-- [A]ctive state -->
										<foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="A"/>
										<!-- take the first title found in the Dublin Core -->
										<foxml:property NAME="info:fedora/fedora-system:def/model#label">
											<xsl:variable name="label" select="($dc//dc:title[normalize-space() != ''])[1]" xmlns:dc="http://purl.org/dc/elements/1.1/"/>
											<xsl:choose>
												<xsl:when test="exists($label)">
													<xsl:attribute name="VALUE" select="substring($label, 1, 255)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:attribute name="VALUE" select="$pid"/>
												</xsl:otherwise>
											</xsl:choose>
										</foxml:property>
									</foxml:objectProperties>
									<!-- Metadata: Dublin Core -->
									<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="DC" STATE="A" CONTROL_GROUP="X">
										<foxml:datastreamVersion ID="DC.0" FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" MIMETYPE="text/xml" LABEL="Dublin Core Record for this object">
											<foxml:xmlContent>
												<xsl:copy-of select="$dc"/>
											</foxml:xmlContent>
										</foxml:datastreamVersion>
									</foxml:datastream>
									<!-- Relations: RELS-EXT -->
									<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="RELS-EXT" STATE="A" CONTROL_GROUP="X" VERSIONABLE="true">
										<foxml:datastreamVersion ID="RELS-EXT.0" LABEL="RDF Statements about this object" MIMETYPE="text/xml">
											<foxml:xmlContent>
												<rdf:RDF xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:islandora="http://islandora.ca/ontology/relsext#">
													<rdf:Description rdf:about="info:fedora/{$cmdID}">
														<!-- OAI -->
														<xsl:if test="sx:evaluate($rec, $oai-include-eval, $NS)">
															<oai:itemID xmlns="http://www.openarchives.org/OAI/2.0/">
																<xsl:value-of select="concat('oai:', $repository, ':', $cmdID)"/>
															</oai:itemID>
														</xsl:if>
														<!-- relationship to the compound -->
														<fedora:isConstituentOf rdf:resource="info:fedora/{$fid}"/>
														<!-- make it the first object in the compound -->
														<xsl:element name="{concat('islandora:isSequenceNumberOf',replace($fid,':','_'))}">
															<xsl:text>1</xsl:text>
														</xsl:element>
														<!-- CMD object has to become a member of the collections the compound is a member of -->
														<xsl:choose>
															<xsl:when test="exists($parents)">
																<xsl:for-each select="$parents">
																	<fedora:isMemberOfCollection rdf:resource="info:fedora/{cmd:lat('lat:',current())}"/>
																</xsl:for-each>
															</xsl:when>
															<xsl:otherwise>
																<xsl:choose>
																	<xsl:when test="exists($collections)">
																		<xsl:for-each select="$collections">
																			<fedora:isMemberOfCollection rdf:resource="info:fedora/{current()}"/>
																		</xsl:for-each>
																	</xsl:when>
																	<xsl:otherwise>
																		<fedora:isMemberOfCollection rdf:resource="info:fedora/islandora:compound_collection"/>
																	</xsl:otherwise>
																</xsl:choose>
															</xsl:otherwise>
														</xsl:choose>
														<!-- a CMD object uses the cmdi content model and is a member of the cmdi collection -->
														<fedora-model:hasModel rdf:resource="info:fedora/islandora:sp_cmdiCModel"/>
													</rdf:Description>
												</rdf:RDF>
											</foxml:xmlContent>
										</foxml:datastreamVersion>
									</foxml:datastream>
									<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="CMD" STATE="A" CONTROL_GROUP="X">
										<foxml:datastreamVersion ID="CMD.0" FORMAT_URI="{/cmd:CMD/@xsii:schemaLocation}" LABEL="CMD Record for this object" MIMETYPE="application/x-cmdi+xml">
											<foxml:xmlContent>
												<xsl:apply-templates mode="cmd">
													<xsl:with-param name="pid" select="$pid" tunnel="yes"/>
													<xsl:with-param name="base" select="$base" tunnel="yes"/>
												</xsl:apply-templates>
											</foxml:xmlContent>
										</foxml:datastreamVersion>
									</foxml:datastream>
									<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="TN" STATE="A" CONTROL_GROUP="E">
										<foxml:datastreamVersion ID="TN.0" LABEL="icon.png" MIMETYPE="image/png">
											<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/metadata.png"/>
										</foxml:datastreamVersion>
									</foxml:datastream>
									<!-- Metadata: other -->
									<xsl:apply-templates mode="other">
										<xsl:with-param name="pid" select="$pid" tunnel="yes"/>
										<xsl:with-param name="base" select="$base" tunnel="yes"/>
									</xsl:apply-templates>
								</foxml:digitalObject>
							</xsl:result-document>
						</xsl:when>
						<xsl:otherwise>
							<xsl:message>WRN: skipped creating CMD FOX[<xsl:value-of select="$cmdFOX"/>], it already exists!</xsl:message>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="CMD" STATE="A" CONTROL_GROUP="X">
						<foxml:datastreamVersion ID="CMD.0" FORMAT_URI="{/cmd:CMD/@xsii:schemaLocation}" LABEL="CMD Record for this object" MIMETYPE="application/x-cmdi+xml">
							<foxml:xmlContent>
								<xsl:apply-templates mode="cmd">
									<xsl:with-param name="pid" select="$pid" tunnel="yes"/>
									<xsl:with-param name="base" select="$base" tunnel="yes"/>
								</xsl:apply-templates>
							</foxml:xmlContent>
						</foxml:datastreamVersion>
					</foxml:datastream>
					<!-- Metadata: other -->
					<xsl:apply-templates mode="other">
						<xsl:with-param name="pid" select="$pid" tunnel="yes"/>
						<xsl:with-param name="base" select="$base" tunnel="yes"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
			<!-- Relations: RELS-EXT -->
			<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="RELS-EXT" STATE="A" CONTROL_GROUP="X" VERSIONABLE="true">
				<foxml:datastreamVersion ID="RELS-EXT.0" LABEL="RDF Statements about this object" MIMETYPE="text/xml">
					<foxml:xmlContent>
						<rdf:RDF xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
							<rdf:Description rdf:about="info:fedora/{$fid}">
								<!-- relationships to (parent) collections -->
								<xsl:choose>
									<xsl:when test="exists($parents)">
										<xsl:for-each select="$parents">
											<fedora:isMemberOfCollection rdf:resource="info:fedora/{cmd:lat('lat:',current())}"/>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<!--<xsl:message>DBG: NO parents[<xsl:value-of select="string-join($parents,', ')"/>] </xsl:message>-->
										<xsl:choose>
											<xsl:when test="exists($collections)">
												<xsl:for-each select="$collections">
													<fedora:isMemberOfCollection rdf:resource="info:fedora/{current()}"/>
												</xsl:for-each>
											</xsl:when>
											<xsl:otherwise>
												<fedora:isMemberOfCollection rdf:resource="info:fedora/islandora:compound_collection"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
								<!-- if the CMD has references to other metadata files it's a collection -->
								<xsl:if test="exists(/cmd:CMD/cmd:Resources/cmd:ResourceProxyList/cmd:ResourceProxy[cmd:ResourceType = 'Metadata'])">
									<fedora-model:hasModel rdf:resource="info:fedora/islandora:collectionCModel"/>
								</xsl:if>
								<!-- if the CMD is a separate object and/or the CMD has references to resources it's a compound -->
								<xsl:if test="$create-cmd-object or exists(/cmd:CMD/cmd:Resources/cmd:ResourceProxyList/cmd:ResourceProxy[cmd:ResourceType = 'Resource'])">
									<fedora-model:hasModel rdf:resource="info:fedora/islandora:compoundCModel"/>
								</xsl:if>
								<!-- if the CMD is part of the compound FOXML it uses the cmdi content model and is member of the cmdi collection -->
								<xsl:if test="not($create-cmd-object)">
									<fedora-model:hasModel rdf:resource="info:fedora/islandora:sp_cmdiCModel"/>
									<!-- OAI -->
									<xsl:if test="sx:evaluate($rec, $oai-include-eval, $NS)">
										<oai:itemID xmlns="http://www.openarchives.org/OAI/2.0/">
											<xsl:value-of select="concat('oai:', $repository, ':', $fid)"/>
										</oai:itemID>
									</xsl:if>
								</xsl:if>
							</rdf:Description>
						</rdf:RDF>
					</foxml:xmlContent>
				</foxml:datastreamVersion>
			</foxml:datastream>
			<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="TN" STATE="A" CONTROL_GROUP="E">
				<foxml:datastreamVersion ID="TN.0" LABEL="icon.png" MIMETYPE="image/png">
					<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/folder.png"/>
				</foxml:datastreamVersion>
			</foxml:datastream>		
			<!-- Resource Proxies -->
			<!--<xsl:message>DBG: resourceProxies[<xsl:value-of select="count(/cmd:CMD/cmd:Resources/cmd:ResourceProxyList/cmd:ResourceProxy[cmd:ResourceType='Resource'])"/>]</xsl:message>
			<xsl:for-each select="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList/cmd:ResourceProxy[cmd:ResourceType='Resource']">
				<xsl:message>DBG: resourceProxy[<xsl:value-of select="position()"/>][<xsl:value-of select="cmd:ResourceRef"/>][<xsl:value-of select="cmd:ResourceRef/@lat:localURI"/>]</xsl:message>
			</xsl:for-each>-->
			<xsl:for-each-group select="/cmd:CMD/cmd:Resources/cmd:ResourceProxyList/cmd:ResourceProxy[cmd:ResourceType = 'Resource']" group-by="cmd:ResourceRef/normalize-space(@lat:localURI)">
				<xsl:for-each select="
						if (current-grouping-key() = '') then
							(current-group())
						else
							(current-group()[1])">
					<xsl:variable name="res" select="current()"/>
					<xsl:variable name="resPID">
						<xsl:choose>
							<xsl:when test="starts-with(cmd:hdl($res/cmd:ResourceRef), 'hdl:')">
								<xsl:sequence select="cmd:hdl($res/cmd:ResourceRef)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:sequence select="resolve-uri($res/cmd:ResourceRef, $base)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="resURI">
						<xsl:choose>
							<xsl:when test="normalize-space($res/cmd:ResourceRef/@lat:localURI) != ''">
								<xsl:sequence select="resolve-uri($res/cmd:ResourceRef/@lat:localURI, $base)"/>
							</xsl:when>
							<xsl:when test="normalize-space($resPID) != ''">
								<xsl:sequence select="resolve-uri($resPID, $base)"/>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="resID" select="cmd:lat('lat:', $resPID)"/>
					<!--<xsl:variable name="resFOX" select="concat($fox-base,'/',replace($resURI,'[^a-zA-Z0-9]','_'),'.xml')"/>-->
					<xsl:variable name="resFOX" select="concat($fox-base, '/', replace($resID, '[^a-zA-Z0-9]', '_'), '.xml')"/>
					<!--<xsl:message>DBG: resourceProxy[<xsl:value-of select="$resURI"/>][<xsl:value-of select="$resFOX"/>][<xsl:value-of select="$resPID"/>][<xsl:value-of select="$resID"/>]</xsl:message>-->
					<!-- take the filepart of the localURI as the resource title -->
					<xsl:variable name="resTitle" select="replace($resURI, '.*/', '')"/>
					<!--<xsl:message>DBG: creating FOX[<xsl:value-of select="$resFOX"/>]?[<xsl:value-of select="not(doc-available($resFOX))"/>]</xsl:message>-->
					<xsl:variable name="resMIME" select="cmd:getMIME($res/cmd:ResourceType/@mimetype,$resURI)"/>
					<xsl:variable name="createFOX" as="xs:boolean">
						<xsl:choose>
							<xsl:when test="(key('rels-to', $resPID))[1]/resolve-uri(dst, src) != $resURI">
								<xsl:message>
									<xsl:text>ERR: resource[</xsl:text>
									<xsl:value-of select="$resURI"/>
									<xsl:text>] has an already used PID URI[</xsl:text>
									<xsl:value-of select="$resPID"/>
									<xsl:text>][</xsl:text>
									<xsl:value-of select="(key('rels-to', $resPID))[1]/resolve-uri(dst, src)"/>
									<xsl:text>]!</xsl:text>
								</xsl:message>
								<xsl:message>
									<xsl:text>WRN: resource FOX[</xsl:text>
									<xsl:value-of select="$resFOX"/>
									<xsl:text>] will not be created!</xsl:text>
								</xsl:message>
								<xsl:sequence select="false()"/>
							</xsl:when>
							<xsl:when test="exists(key('rels-from', $resPID)[Type = 'Resource'])">
								<xsl:message>
									<xsl:text>ERR: resource[</xsl:text>
									<xsl:value-of select="$resURI"/>
									<xsl:text>] has a PID[</xsl:text>
									<xsl:value-of select="$resPID"/>
									<xsl:text>] already used by one or more CMDI records[</xsl:text>
									<xsl:value-of select="string-join(key('rels-from', $resPID)[Type = 'Resource']/src, ', ')"/>
									<xsl:text>]!</xsl:text>
								</xsl:message>
								<xsl:message>
									<xsl:text>WRN: resource FOX[</xsl:text>
									<xsl:value-of select="$resFOX"/>
									<xsl:text>] will not be created!</xsl:text>
								</xsl:message>
								<xsl:sequence select="false()"/>
							</xsl:when>
							<xsl:when test="not(sx:checkURL(replace($resPID, '^hdl:', 'http://hdl.handle.net/')))">
								<xsl:message>
									<xsl:text>ERR: resource[</xsl:text>
									<xsl:value-of select="$resURI"/>
									<xsl:text>] has an invalid PID URI[</xsl:text>
									<xsl:value-of select="$resPID"/>
									<xsl:text>]!</xsl:text>
								</xsl:message>
								<xsl:message>
									<xsl:text>WRN: resource FOX[</xsl:text>
									<xsl:value-of select="$resFOX"/>
									<xsl:text>] will not be created!</xsl:text>
								</xsl:message>
								<xsl:sequence select="false()"/>
							</xsl:when>
							<xsl:when test="normalize-space($resURI) = ''">
								<xsl:message>
									<xsl:text>ERR: resource URI is empty, i.e., unknown!</xsl:text>
								</xsl:message>
								<xsl:message>
									<xsl:text>WRN: resource FOX[</xsl:text>
									<xsl:value-of select="$resFOX"/>
									<xsl:text>] will not be created!</xsl:text>
								</xsl:message>
								<xsl:sequence select="false()"/>
							</xsl:when>
							<xsl:when test="starts-with($resURI, 'file:') and exists($import-base) and sx:fileExists(replace($resURI, $conversion-base, $import-base))">
								<xsl:sequence select="true()"/>
							</xsl:when>
							<xsl:when test="starts-with($resURI, 'file:') and not(sx:fileExists($resURI))">
								<xsl:variable name="uri">
									<xsl:choose>
										<xsl:when test="exists($import-base)">
											<xsl:sequence select="replace($resURI, $conversion-base, $import-base)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:sequence select="$resURI"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:choose>
									<xsl:when test="$lax-resource-check">
										<xsl:message>
											<xsl:text>WRN: resource[</xsl:text>
											<xsl:value-of select="$uri"/>
											<xsl:text>] linked from [</xsl:text>
											<xsl:value-of select="base-uri()"/>
											<xsl:text>] doesn't exist!</xsl:text>
										</xsl:message>
										<xsl:message>
											<xsl:text>WRN: resource FOX[</xsl:text>
											<xsl:value-of select="$resFOX"/>
											<xsl:text>] will be created anyway</xsl:text>
										</xsl:message>
										<xsl:sequence select="true()"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:message>
											<xsl:text>ERR: resource[</xsl:text>
											<xsl:value-of select="$uri"/>
											<xsl:text>] linked from [</xsl:text>
											<xsl:value-of select="base-uri()"/>
											<xsl:text>] doesn't exist!</xsl:text>
										</xsl:message>
										<xsl:message>
											<xsl:text>WRN: resource FOX[</xsl:text>
											<xsl:value-of select="$resFOX"/>
											<xsl:text>] will not be created!</xsl:text>
										</xsl:message>
										<xsl:sequence select="false()"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<xsl:sequence select="true()"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$createFOX and not(doc-available($resFOX))">
						<xsl:message>
							<xsl:text>DBG: creating resource FOX[</xsl:text>
							<xsl:value-of select="$resFOX"/>
							<xsl:text>]</xsl:text>
						</xsl:message>
						<xsl:result-document href="{$resFOX}">
							<foxml:digitalObject VERSION="1.1" PID="{$resID}" xmlns:xsii="http://www.w3.org/2001/XMLSchema-instance" xsii:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
								<xsl:comment>
									<xsl:text>Source: </xsl:text>
									<xsl:value-of select="$resURI"/>
								</xsl:comment>
								<foxml:objectProperties>
									<!-- [A]ctive state -->
									<foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="A"/>
									<foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="{substring($resTitle,1,255)}"/>
								</foxml:objectProperties>
								<!-- Metadata: Dublin Core -->
								<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="DC" STATE="A" CONTROL_GROUP="X">
									<foxml:datastreamVersion ID="DC.0" FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/" MIMETYPE="text/xml" LABEL="Dublin Core Record for this object">
										<foxml:xmlContent>
											<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
												<dc:title>
													<xsl:value-of select="$resTitle"/>
												</dc:title>
											</oai_dc:dc>
										</foxml:xmlContent>
									</foxml:datastreamVersion>
								</foxml:datastream>
								<!-- Relations: RELS-EXT -->
								<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="RELS-EXT" STATE="A" CONTROL_GROUP="X" VERSIONABLE="true">
									<foxml:datastreamVersion ID="RELS-EXT.0" LABEL="RDF Statements about this object" MIMETYPE="text/xml">
										<foxml:xmlContent>
											<rdf:RDF xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
												<rdf:Description rdf:about="info:fedora/{$resID}">
													<!-- relationships to (parent) compounds -->
													<xsl:variable name="compounds" select="
															distinct-values($rels-doc/key('rels-to', ($resPID,
															$resURI))[type = 'Resource']/from)"/>
													<xsl:choose>
														<xsl:when test="exists($compounds)">
															<xsl:for-each select="$compounds">
																<fedora:isConstituentOf rdf:resource="info:fedora/{cmd:lat('lat:',current())}"/>
															</xsl:for-each>
														</xsl:when>
														<xsl:otherwise>
															<!-- the resource should be at least a member of the compound we're creating -->
															<fedora:isConstituentOf rdf:resource="info:fedora/{$fid}"/>
														</xsl:otherwise>
													</xsl:choose>
													<!-- resource has to become a member of the collection the compound is a member of -->
													<xsl:choose>
														<xsl:when test="exists($parents)">
															<xsl:for-each select="$parents">
																<fedora:isMemberOfCollection rdf:resource="info:fedora/{cmd:lat('lat:',current())}"/>
															</xsl:for-each>
														</xsl:when>
														<xsl:otherwise>
															<xsl:choose>
																<xsl:when test="exists($collections)">
																	<xsl:for-each select="$collections">
																		<fedora:isMemberOfCollection rdf:resource="info:fedora/{current()}"/>
																	</xsl:for-each>
																</xsl:when>
																<xsl:otherwise>
																	<fedora:isMemberOfCollection rdf:resource="info:fedora/islandora:compound_collection"/>
																</xsl:otherwise>
															</xsl:choose>
														</xsl:otherwise>
													</xsl:choose>
													<!-- add specific content models for specific MIME types -->
													<xsl:choose>
														<xsl:when test="starts-with($resMIME,'audio/')">
															<fedora-model:hasModel rdf:resource="info:fedora/islandora:sp-audioCModel"/>
														</xsl:when>
													</xsl:choose>
												</rdf:Description>
											</rdf:RDF>
										</foxml:xmlContent>
									</foxml:datastreamVersion>
								</foxml:datastream>
								<foxml:datastream xmlns:foxml="info:fedora/fedora-system:def/foxml#" ID="OBJ" STATE="A">
									<!--- CHECK: CONTROL_GROUP indicates the kind of datastream, either
                                                            Externally Referenced Content (E), 
                                                            Redirected Content (R), 
                                                            Managed Content (M) or 
                                                            Inline XML (X) -->
									<xsl:choose>
										<xsl:when test="starts-with($resURI, 'file:')">
											<xsl:attribute name="CONTROL_GROUP" select="'E'"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:attribute name="CONTROL_GROUP" select="'R'"/>
										</xsl:otherwise>
									</xsl:choose>
									<foxml:datastreamVersion ID="OBJ.0" LABEL="{substring($resTitle,1,255)}" MIMETYPE="{cmd:getMIME($res/cmd:ResourceType/@mimetype,$resURI)}">
										<foxml:contentLocation TYPE="URL">
											<xsl:choose>
												<xsl:when test="starts-with($resURI, 'file:') and exists($import-base)">
													<xsl:attribute name="REF" select="replace($resURI, $conversion-base, $import-base)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:attribute name="REF" select="replace($resURI, '^hdl:', 'http://hdl.handle.net/')"/>
												</xsl:otherwise>
											</xsl:choose>
										</foxml:contentLocation>
									</foxml:datastreamVersion>
								</foxml:datastream>
								<!-- add specific content models for specific MIME types -->
								<foxml:datastream ID="TN" STATE="A" CONTROL_GROUP="E">
									<foxml:datastreamVersion ID="TN.0" LABEL="icon.png" MIMETYPE="image/png">
										<xsl:choose>
											<xsl:when test="starts-with($resMIME,'audio/')">
												<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/audio.png"/>
											</xsl:when>
											<xsl:when test="starts-with($resMIME,'image/')">
												<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/image.png"/>
											</xsl:when>
											<xsl:when test="starts-with($resMIME,'text/')">
												<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/text.png"/>
											</xsl:when>
											<xsl:when test="starts-with($resMIME,'video/')">
												<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/video.png"/>
											</xsl:when>
											<xsl:otherwise>
												<foxml:contentLocation TYPE="URL" REF="file:{$icon-base}/other.png"/>
											</xsl:otherwise>
										</xsl:choose>
									</foxml:datastreamVersion>
								</foxml:datastream>
							</foxml:digitalObject>
						</xsl:result-document>
					</xsl:if>
				</xsl:for-each>
			</xsl:for-each-group>
		</foxml:digitalObject>
	</xsl:template>
	
	<!-- MIME types -->
	<xsl:function name="cmd:getMIME" as="xs:string">
		<xsl:param name="mime"/>
		<xsl:param name="uri"/>
		<xsl:variable name="ext" select="tokenize($uri, '\.')[last()]"/>
		<xsl:choose>
			<xsl:when test="normalize-space($mime)!=''">
				<xsl:sequence select="$mime"/>
			</xsl:when>
			<xsl:when test="normalize-space($ext)!=''">
				<xsl:choose>
					<xsl:when test="$ext=('wav')">
						<xsl:sequence select="'audio/wav'"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:message>WRN: can't determine the MIME type for extension[<xsl:value-of select="$ext"/>] of resource URI[<xsl:value-of select="$uri"/>], falling back to application/octet-stream!</xsl:message>
						<xsl:sequence select="'application/octet-stream'"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>WRN: can't determine the MIME type for resource URI[<xsl:value-of select="$uri"/>], falling back to application/octet-stream!</xsl:message>
				<xsl:sequence select="'application/octet-stream'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- CMDI -->

	<!-- identity copy -->
	<xsl:template match="@* | node()" mode="cmd">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()" mode="#current"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="cmd:Header" mode="cmd">
		<xsl:param name="pid" tunnel="yes"/>
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="#current"/>
			<xsl:apply-templates select="cmd:MdCreator | cmd:MdCreationDate" mode="#current"/>
			<MdSelfLink xmlns="http://www.clarin.eu/cmd/">
				<xsl:copy-of select="cmd:MdSelfLink/@* except @lat:localURI"/>
				<xsl:attribute name="lat:localURI" select="cmd:lat('lat:', $pid)"/>
				<xsl:value-of select="$pid"/>
			</MdSelfLink>
			<xsl:apply-templates select="node() except (cmd:MdCreator | cmd:MdCreationDate | cmd:MdSelfLink)" mode="#current"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="cmd:ResourceRef" mode="cmd">
		<xsl:param name="base" tunnel="yes"/>
		<xsl:variable name="pid">
			<xsl:choose>
				<xsl:when test="normalize-space(.) = ''">
					<xsl:sequence select="()"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:sequence select="resolve-uri(., $base)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="lcl">
			<xsl:choose>
				<xsl:when test="normalize-space(@lat:localURI) = ''">
					<xsl:sequence select="()"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:sequence select="resolve-uri(@lat:localURI, $base)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="lvl">
			<xsl:choose>
				<xsl:when test="
						../cmd:ResourceType = ('Metadata',
						'Resource')">
					<xsl:sequence select="'ERR'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:sequence select="'WRN'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="hdl" select="
				cmd:pid(($pid,
				$lcl), $lvl)"/>
		<xsl:choose>
			<xsl:when test="starts-with($pid, 'file:') or starts-with($lcl, 'file:')">
				<xsl:choose>
					<xsl:when test="empty($hdl)">
						<xsl:copy>
							<xsl:apply-templates select="@* | node()" mode="#current"/>
						</xsl:copy>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy>
							<xsl:apply-templates select="@* except @lat:localURI" mode="#current"/>
							<xsl:attribute name="lat:localURI" xmlns:lat="http://lat.mpi.nl/">
								<xsl:value-of select="cmd:lat('lat:', $hdl)"/>
							</xsl:attribute>
							<xsl:value-of select="$hdl"/>
						</xsl:copy>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*" mode="#current"/>
					<xsl:choose>
						<xsl:when test="empty($hdl)">
							<xsl:apply-templates select="node()" mode="#current"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$hdl"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- turn @lat:localURI into a lat: reference -->
	<xsl:template match="@lat:localURI" priority="1" mode="cmd">
		<xsl:attribute name="lat:localURI" xmlns:lat="http://lat.mpi.nl/">
			<xsl:value-of select="cmd:lat('lat:', parent::cmd:ResourceRef)"/>
		</xsl:attribute>
	</xsl:template>

	<!-- Dublin Core -->
	<xsl:template match="cmd:CMD" mode="dc">
		<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
			<!-- nothing, please overwrite with your own template -->
		</oai_dc:dc>
	</xsl:template>

	<!-- Other -->
	<xsl:template match="cmd:CMD" mode="other"/>

</xsl:stylesheet>