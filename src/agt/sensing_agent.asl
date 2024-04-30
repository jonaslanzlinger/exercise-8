// sensing agent


/* Initial beliefs and rules */

// Task 2.1.2: Reason on the organization and adoption of relevant roles
role_goal(R, G) :-
   role_mission(R, _, M) & mission_goal(M, G).

can_achieve(G) :-
   .relevant_plans({+!G[scheme(_)]}, LP) & LP \== [].

i_have_plan_for_role(R) :-
   not (role_goal(R, G) & not can_achieve(G)).


/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

// Task 2.1.1: Reacting to the creation of new organization workspaces
@org_created_plan
+org_created(OrgName) : true <-
	joinWorkspace(OrgName);
	lookupArtifact(OrgName, OrgArtId);
	focus(OrgArtId).

// Listening to the observable properties of the organization
@group_plan
+group(GroupId, GroupType, GroupArtId) : true <-
	focus(GroupArtId);
	!scan_group_specification(GroupArtId).

// Listening to the observable properties of the organization
@scheme_plan
+scheme(SchemeId, SchemeType, SchemeArtId) : true <-
	focus(SchemeArtId).

// Task 2.1.2: Reasoning on the organization and adoption of relevant roles
@scan_group_specification_plan
+!scan_group_specification(GroupArtId) : specification(group_specification(GroupName,RolesList,_,_)) <-
	for ( .member(Role,RolesList) ) {
    !reasoning_for_role_adoption(Role);
	}.

// Task 2.1.2: Reasoning on the organization and adoption of relevant roles
@reasoning_for_role_adoption_plan
+!reasoning_for_role_adoption(role(Role,_,_,MinCard,MaxCard,_,_)) : i_have_plan_for_role(Role) <-
	.print("I have a plan for the role: ", Role);
	adoptRole(Role).

// Task 2.1.2: Fail plan for reasoning on the organization and adoption of relevant roles
@reasoning_for_role_adoption_plan_fail
+!reasoning_for_role_adoption(role(Role,_,_,MinCard,MaxCard,_,_)) : true <-
	true.

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }