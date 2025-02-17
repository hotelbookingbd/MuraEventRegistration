<cfcomponent displayName="Event Registration Routines">

	<cffunction name="QRCodeImage" ReturnType="String" output="False">
		<cfargument name="Data" type="string" Required="True">
		<cfargument name="PluginDirectory" type="string" Required="True">
		<cfargument name="QRCodeImageFilename" type="string" Required="True">

		<cfset qr = createObject("component","plugins/#Arguments.PluginDirectory#/library/components/QRCode")>
		<cfset CurLoc = #ExpandPath("/")#>
		<cfset FileStoreLoc = #Variables.CurLoc# & "plugins/" & #Arguments.PluginDirectory# & "/library/images/QRCodes">
		<cfset ImageFilename = #Arguments.QRCodeImageFilename# & ".png">
		<cfset FileWritePathWithName = #Variables.FileStoreLoc# & "/" & #Variables.ImageFilename#>
		<cfset URLFileLocation = "/plugins/" & #Arguments.PluginDirectory# & "/library/images/QRCodes/" & #Variables.ImageFilename#>
		<cffile action="write" file="#Variables.FileWritePathWithName#" output="#qr.getQRCode("#Arguments.Data#",100,100,"png")#">
		<cfreturn #Variables.URLFileLocation#>
	</cffunction>

	<cffunction name="BarcodeImage" ReturnType="String" output="False">
		<cfargument name="Data" type="string" Required="True">
		<cfargument name="PluginDirectory" type="string" Required="True">
		<cfargument name="BarcodeImageFilename" type="string" Required="True">

		<cfset RegistrationIDBarcode = createObject("component","plugins/#Arguments.PluginDirectory#/library/components/BarbecueService")>
		<cfset CurLoc = #ExpandPath("/")#>
		<cfset FileStoreLoc = #Variables.CurLoc# & "plugins/" & #Arguments.PluginDirectory# & "/library/images/BarCodeTemp">
		<cfset ImageFilename = #Arguments.BarcodeImageFilename# & ".jpg">
		<cfset FileWritePathWithName = #Variables.FileStoreLoc# & "/" & #Variables.ImageFilename#>
		<cfset URLFileLocation = "/plugins/" & #Arguments.PluginDirectory# & "/library/images/BarCodeTemp/" & #Variables.ImageFilename#>
		<cffile action="write" file="#Variables.FileWritePathWithName#" output="#RegistrationIDBarcode.barcodeToBrowser(Arguments.Data)#">
		<cfreturn #Variables.URLFileLocation#>
	</cffunction>

	<cffunction name="GetLatitudeLongitudeProximity" ReturnType="Numeric" output="False">
		<cfargument name="FromLatitude" type="numeric" required="true" hint="I am the starting Latitude Value">
		<cfargument name="FromLongitude" type="numeric" required="true" hint="I am the starting Longitude Value">
		<cfargument name="ToLatitude" type="numeric" required="true" hint="I am the ending Latitude Value">
		<cfargument name="ToLongitude" type="numeric" required="true" hint="I am the ending Longitude Value">

		<cfset var LOCAL = {}>
		<cfset LOCAL.MilesPerLatitude = 69.09>
		<cfset LOCAL.DegreeDistance = RadiansToDegrees(
			ACos(
				Sin(DegreesToRadians(Arguments.FromLatitude)) * Sin(DegreesToRadians(Arguments.ToLatitude))
			)
			+
			(
				COS(DegreesToRadians(Arguments.FromLatitude)) * Cos(DegreesToRadians(Arguments.ToLatitude)) * COS(DegreesToRadians(Arguments.ToLongitude - Arguments.FromLognitude))
			)
		) />
		cfreturn Round(Local.DegreeDistance * LOCAL.MilesPerLatitude) />
	</cffunction>

	<cffunction name="DegreesToRadians" returntype="numeric" output="false" hint="I convert degrees to radians.">
		<cfargument name="Degrees" type="numeric" required="true" hint="I am the degree value to be converted to radians.">
		<cfreturn (Arguments.Degrees * PI() / 180) />
	</cffunction>

	<cffunction name="RadiansToDegrees" returntype="numeric" output="false" hint="I convert radians to degrees">
		<cfargument name="Radians" type="numeric" required="true" hint="I am the radian value to be converted to degrees.">
		<cfreturn (Arguments.Radians * 180 / PI()) />
	</cffunction>

	<cffunction name="iCalUS" returntype="String" output="false" hint="Create iCal Event for Registered Users">
		<cfargument name="RegistrationRecordID" required="true" type="numeric">

		<cfquery name="getRegistration" Datasource="#Session.FormData.PluginInfo.Datasource#" username="#Session.FormData.PluginInfo.DBUsername#" password="#Session.FormData.PluginInfo.DBPassword#">
			Select RegistrationID, RegistrationDate, User_ID, EventID, RequestsMeal, IVCParticipant, AttendeePrice, RegisterByUserID, OnWaitingList, Comments, WebinarParticipant
			From eRegistrations
			Where TContent_ID = <cfqueryparam value="#Arguments.RegistrationRecordID#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfquery name="getEvent" Datasource="#Session.FormData.PluginInfo.Datasource#" username="#Session.FormData.PluginInfo.DBUsername#" password="#Session.FormData.PluginInfo.DBPassword#">
			Select ShortTitle, EventDate, EventDate1, EventDate2, EventDate3, EventDate4, LongDescription, Event_StartTime, Event_EndTime, PGPPoints, MealProvided, AllowVideoConference, VideoConferenceInfo, EventAgenda, EventTargetAudience, EventStrategies, EventSpecialInstructions, LocationType, LocationID, LocationRoomID, Facilitator, WebinarAvailable, WebinarConnectInfo, WebinarMemberCost, WebinarNonMemberCost
			From eEvents
			Where TContent_ID = <cfqueryparam value="#getRegistration.EventID#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfquery name="getEventLocation" Datasource="#Session.FormData.PluginInfo.Datasource#" username="#Session.FormData.PluginInfo.DBUsername#" password="#Session.FormData.PluginInfo.DBPassword#">
			Select FacilityName, PhysicalAddress, PhysicalCity, PhysicalState, PhysicalZipCode, PrimaryVoiceNumber, GeoCode_Latitude, GeoCode_Longitude
			From eFacility
			Where FacilityType = '#getEvent.LocationType#' and TContent_ID = #getEvent.LocationID#
		</cfquery>

		<cfquery name="getRegisteredUserInfo" Datasource="#Session.FormData.PluginInfo.Datasource#" username="#Session.FormData.PluginInfo.DBUsername#" password="#Session.FormData.PluginInfo.DBPassword#">
			Select Fname, Lname, Email
			From tusers
			Where UserID = <cfqueryparam value="#getRegistration.User_ID#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfquery name="getEventFacilitator" Datasource="#Session.FormData.PluginInfo.Datasource#" username="#Session.FormData.PluginInfo.DBUsername#" password="#Session.FormData.PluginInfo.DBPassword#">
			Select Fname, Lname, Email
			From tusers
			Where UserID = <cfqueryparam value="#getEvent.Facilitator#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfset CRLF = #chr(13)# & #chr(10)#>
		<cfset CurrentDateTime = #Now()#>
		<cfset stEvent = StructNew()>
		<cfset stEvent.FacilitatorName = #getEventFacilitator.Fname# & " " & #getEventFacilitator.Lname#>
		<cfset stEvent.FacilitatorEmail = #getEventFacilitator.Email#>
		<cfset stEvent.EventLocation = #getEventLocation.FacilityName# & " (" & #getEventLocation.PhysicalAddress# & " " & #getEventLocation.PhysicalCity# & ", " & #getEventLocation.PhysicalState# & " " & #getEventLocation.PhysicalZipCode# & ")">
		<cfset stEvent.EventDescription = #getEvent.LongDescription# & "\n\n" & "Special Instructions:\n" & #getEvent.EventSpecialInstructions#>
		<cfset stEvent.Priority = 1>

		<cfset vCal = "BEGIN:VCALENDAR" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "PRODID: -//Northern Indiana ESC//Event Registration System//EN" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "VERSION:2.0" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "METHOD:REQUEST" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "BEGIN:VTIMEZONE" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZID:Eastern Time" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "BEGIN:STANDARD" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "DTSTART:20061101T020000" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=1SU;BYMONTH=11" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZOFFSETFROM:-0400" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZOFFSETTO:-0500" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZNAME:Standard Time" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "END:STANDARD" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "BEGIN:DAYLIGHT" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "DTSTART:20060301T020000" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "RRULE:FREQ=YEARLY;INTERVAL=1;BYDAY=2SU;BYMONTH=3" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZOFFSETFROM:-0500" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZOFFSETTO:-0400" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TZNAME:Daylight Savings Time" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "END:DAYLIGHT" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "END:VTIMEZONE" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "BEGIN:VEVENT" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "UID:" & #getRegistration.RegistrationID# & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "ORGANIZER;CN=:" & #stEvent.FacilitatorName# & ":MAILTO:" & #stEvent.FacilitatorEmail# & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "DTSTAMP:" & #DateFormat(Now(), "yyyymmdd")# & "T" & TimeFormat(Now(), "HHmmss") & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "DTSTART;TZID=Eastern Time:" & #DateFormat(getEvent.EventDate, "yyyymmdd")# & "T" & TimeFormat(getEvent.Event_StartTime, "HHmmss") & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "DTEND;TZID=Eastern Time:" & #DateFormat(getEvent.EventDate, "yyyymmdd")# & "T" & TimeFormat(getEvent.Event_EndTime, "HHmmss") & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "SUMMARY:" & #getEvent.ShortTitle# & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "LOCATION:" & #stEvent.EventLocation# & #Variables.CRLF#>
		<cfif getRegistration.WebinarParticipant EQ 0>
			<cfset vCal = #Variables.vCal# & "DESCRIPTION:" & #stEvent.EventDescription# & #Variables.CRLF#>
		<cfelseif getRegistration.WebinarParticipant EQ 1 AND getEvent.WebinarAvailable EQ 1>
			<cfset vCal = #Variables.vCal# & "DESCRIPTION:" & #stEvent.EventDescription# & #Variables.CRLF#>
			<cfset vCal = #Variables.vCal# & "Webinar Information: " & #getEvent.WebinarConnectInfo# & #Variables.CRLF#>
		</cfif>
		<cfset vCal = #Variables.vCal# & "PRIORITY:" & #stEvent.Priority# & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "TRANSP:OPAQUE" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "CLASS:PUBLIC" & #Variables.CRLF#>
		<!---
			For a Reminder Use the Below Lines
			<cfset vCal = #Variables.vCal# & "BEGIN:VALARM" & #Variables.CRLF#>
			<cfset vCal = #Variables.vCal# & "TRIGGER:-PT30M" & #Variables.CRLF#>
			<cfset vCal = #Variables.vCal# & "ACTION:DISPLAY" & #Variables.CRLF#>
			<cfset vCal = #Variables.vCal# & "DESCRIPTION:Reminder" & #Variables.CRLF#>
			<cfset vCal = #Variables.vCal# & "END:VALARM" & #Variables.CRLF#>

		--->
		<cfset vCal = #Variables.vCal# & "END:VEVENT" & #Variables.CRLF#>
		<cfset vCal = #Variables.vCal# & "END:VCALENDAR" & #Variables.CRLF#>
		<cfreturn Trim(variables.vcal)>
	</cffunction>

	<cffunction name="UpcomingEvents" ReturnType="Query" Access="Remote" Output="False"  hint="Returns Upcoming Events">
		<cfargument name="DaysInFuture" required="true" type="Number">
		<cfargument name="SiteID" required="true" type="String">

		<cfset DateInFuture = #DateFormat(DateAdd("d", Now(), Arguments.DaysInFuture), "yyyy-mm-dd")#>
		<cfset TodayDate = #DateFormat(Now(), "yyyy-mm-dd")#>

		<cfquery name="getEvent" Datasource="NIESCEventRegistration" username="CFAppsMySQL" password="CFAppsMySQL">
			Select eEvents.TContent_ID, eEvents.ShortTitle, eEvents.EventDate
			From eEvents
			Where eEvents.EventDate > <cfqueryparam value="#Variables.TodayDate#" cfsqltype="cf_sql_date"> and
				eEvents.EventDate < <cfqueryparam value="#Variables.DateInFuture#" cfsqltype="cf_sql_date"> and
				eEvents.Site_ID = <cfqueryparam value="#Arguments.SiteID#" cfsqltype="cf_sql_varchar"> and
				eEvents.Active = 1
			Order by EventDate ASC
		</cfquery>
		<cfreturn getEvent>

		<cfif getEvent.RecordCount>
			<cfsavecontent variable="xmlData">
			<?xml version="1.0" encoding="UTF-8"?>
			<cfoutput><UpComingEvents><cfloop query="getEvent"><Event ID="#getEvent.TContent_ID#">
					<DateOfEvent>#DateFormat(getEvent.EventDate, "mm-dd-yyyy")#</DateOfEvent>
					<EventTitle>#getEvent.ShortTitle#</EventTitle>
					<EventMoreInfo>http://events.niesc.k12.in.us/plugins/EventRegistration/index.cfm?EventRegistrationaction=public:events.eventinfo&EventID=#getEvent.TContent_ID#</EventMoreInfo>
				</Event></cfloop></UpComingEvents></cfoutput>
			</cfsavecontent>
			<cfreturn RTrim(LTrim(Variables.xmlData))>
		<cfelse>
			<cfsavecontent variable="xmlData">
			<?xml version="1.0" encoding="UTF-8"?>
			<cfoutput><UpComingEvents>
				<NumberEvents>0</NumberEvents>
				<EventInfo></EventInfo>
			</UpComingEvents></cfoutput>
			</cfsavecontent>
			<cfreturn RTrim(LTrim(Variables.xmlData))>
		</cfif>
	</cffunction>

</cfcomponent>