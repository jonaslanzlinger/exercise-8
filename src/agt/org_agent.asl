// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

// Task 2.2.1: Infere whether the group has enough players for a role
has_enough_players_for(R) :-
  role_cardinality(R,Min,Max) &
  .count(play(_,R,_),NP) &
  NP >= Min.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Hello world");

  // Task 1.1: Create and join organization workspace "lab_monitoring_org"
  createWorkspace(OrgName);
  joinWorkspace(OrgName, WorkspaceId);

  // Task 1.2: Create and focus on the organization board artifact
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoardArtId)[wid(WorkspaceId)];
  focus(OrgBoardArtId)[wid(WorkspaceId)];

  // Task 1.3: Create and focus on the group and scheme artifacts
  createGroup(GroupName, GroupName, GroupArtId)[artifact_id(OrgBoardArtId)];
  focus(GroupArtId)[wid(WorkspaceId)];
  createScheme(SchemeName, SchemeName, SchemeArtId)[artifact_id(OrgBoardArtId)];
  focus(SchemeArtId)[wid(WorkspaceId)];

  // Task 1.4: Broadcast the creation of the organization
  .broadcast(tell, org_created(OrgName));

  !inspect(GroupArtId)[wid(WorkspaceId)];
  !inspect(SchemeArtId)[wid(WorkspaceId)];

  // Task 1.5: Add test goal for the formation status of the group, and wait for the group to become well-formed
  ?formationStatus(ok)[artifact_id(GroupArtId)].


/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(GroupArtId)] : group(GroupName,_,GroupArtId)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  // Task 2.2.1: Wait 15 seconds until actively striving for the group to become well-formed
  .wait(15000);
  !complete_group_formation(GroupName);
  .wait({+formationStatus(ok)[artifact_id(GroupArtId)]}). // waits until the belief is added in the belief base

// Task 1.5: Reacting to the addition of the belief formationStatus(ok)
@formation_status_is_ok_plan
+formationStatus(ok)[artifact_id(GroupArtId)] : group(GroupName,_,GroupArtId)[artifact_id(OrgName)] & scheme(SchemeName,SchemeType,SchemeArtId) <-
  .print("Group ", GroupName, " is well-formed and can work on the scheme.");
  addScheme(SchemeName)[artifact_id(GroupArtId)];
  focus(SchemeArtId).

// Task 2.2.1: Actively striving for the group to become well-formed each 15 seconds
@complete_group_formation_plan
+!complete_group_formation(GroupName) : formationStatus(nok) & group(GroupName,GroupType,GroupArtId) & org_name(OrgName) <-
  if (not has_enough_players_for(temperature_reader)) {
    .print("Not enough players for role: temperature_reader");
    .broadcast(tell, ask_fulfill_role(temperature_reader, GroupName, OrgName));
  }
  if (not has_enough_players_for(temperature_manifestor)) {
    .print("Not enough players for role: temperature_manifestor");
    .broadcast(tell, ask_fulfill_role(temperature_manifestor, GroupName, OrgName));
  }
  .wait(15000);
  if (not (has_enough_players_for(temperature_reader) & has_enough_players_for(temperature_manifestor))) {
    !complete_group_formation(GroupArtId);
  }.

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }