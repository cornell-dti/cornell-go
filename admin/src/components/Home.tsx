export function Home() {
  return (
    <>
      <h3>Welcome to the CornellGO Manager!</h3>
      <br />
      To approve any admins, go the Admin Approval page <br />
      <br />
      To start, go to the Events page to edit the events on the server <br />
      Id: unique identifier for this event <br />
      Available Until: when this event will expire (not be usable) <br />
      Required Players: how many players are necessary to participate in the
      event <br />
      Rewarding Method: "Unlimited" for unlimited copies of a reward or no
      reward, "Limited" for a limited number of rewards <br />
      Minimum Rewarding Score: minimum amount of challenges to complete before
      getting a reward <br />
      Skipping Enabled: if players are allowed to skip ahead before finishing a
      challenge <br />
      Default: ignore this <br />
      Publicly Visible: if this event should be visible to the public <br />
      <br />
      To edit challenges of events, select an event from the Events page, and
      switch to the Challenges page to continue editing
      <br />
      Id: unique identifier for this challenge <br />
      Awarding Distance: the distance before a challenge is complete <br />
      Close Distance: the distance before a player is considered close <br />
      UP/DOWN: change the order of challenges in the selected event <br />
      <br />
      To edit rewards of events, select an event from the Events page, and
      switch to the Rewards page to continue editing
      <br />
      Id: unique identifier for this reward <br />
      Redeem info: the information to redeem this reward (can be empty or
      contain clickable links) <br />
      Claiming User Id: the unique identifier of a the user who has earned this
      reward (empty if none)
      <br /> <br />
      To create organizations for groups of people, go to Organizations and
      create a group (be careful with the naming since it's visible people in
      the groups, and the name must be unique). <br />
      To restrict these groups to certain events, select an event in the Events
      page and click Add Event on the group <br />
      If you want to make temporary users for the restricted group, enter the
      number of users you want to create <br />
      You will not be able to decrease the amount of generated users, but you
      can increase it. You will need to delete the whole organization to remove
      users. <br />
      Events that are not publicly visible but are in a organization will be
      visible to all people who are in that organization
      <br />
      Whenever you want to test an event before making it public, be sure to
      make a organization and test using it, then delete the organization (it
      will remove your test account from the leaderboard)
    </>
  );
}
