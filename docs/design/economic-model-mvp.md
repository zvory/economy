# Economic model MVP

## Purpose

The first economic-model MVP proves that a small, fully planned physical economy can be controlled,
simulated, saved, replayed, and inspected. It is a foundation for later economic systems, not an
attempt to simulate markets, households, or recessions.

The player acts as the central planner. The player decides what sectors should produce, where labor
should be assigned, and how scarce goods and transportation should be allocated. The engine
determines what can actually happen given capacity, inputs, inventories, labor, and transit time.

The MVP is successful when the player can industrialize a simple agrarian economy and understand
why every production target was met or missed.

## Scope boundary

The MVP models physical quantities only. It has no money, prices, wages, profits, ownership income,
or autonomous investment. Scarcity appears as unmet demand, unfilled orders, idle capacity, and
allocation conflicts.

Population is aggregate. There are no individual people, households, voluntary job choices, or
special peasant agents. A peasant is labor assigned to farming; an industrial worker is labor
assigned to an industrial sector.

Food is an ordinary good. A farm is an ordinary production sector. Farm workers create food demand
through the same population-demand system as everyone else; the farm itself does not consume their
food. If one farm worker produces only slightly more food than one population unit requires, most
labor must remain in agriculture. Higher farm productivity can later free labor for industry
without requiring a special industrialization rule.

## Required content

The initial scenario must define at least these goods:

- Food
- Cotton
- Timber
- Clothing
- Furniture

It must define at least these sectors:

| Sector | Required inputs | Output |
| --- | --- | --- |
| Farm | Labor | Food |
| Cotton plantation | Labor | Cotton |
| Logging | Labor | Timber |
| Clothing manufacturing | Labor and cotton | Clothing |
| Furniture manufacturing | Labor and timber | Furniture |
| Barge transportation | Labor | Route transport capacity |

The initial map must contain multiple inventory locations and at least one river route with finite
weekly capacity and a transit time of at least one week. At least one raw material must travel to
manufacturing, and at least one finished good must travel to its consumers.

Goods, sectors, recipes, demand coefficients, capacities, locations, routes, and transit times must
be content data rather than engine code dedicated to cotton, timber, clothing, or furniture.

## Functional requirements

### Population and labor

- The simulation must track aggregate total population and available labor.
- A configured participation assumption may convert population into available labor. Consumption
  by non-workers or dependents may be folded into per-worker demand coefficients for this MVP.
- Available labor must be assigned among sectors. Labor cannot be used by more than one sector in
  the same week.
- The player must be able to set target labor assignments directly.
- Actual assignments must move toward the targets at a configurable maximum weekly reassignment
  rate. Command authority removes worker choice, but it does not remove training, relocation, and
  administrative delay.
- The engine must report current assignment, target assignment, reassignment in progress, and any
  target that cannot be filled.

### Final demand

- Final demand must be derived from aggregate population and its current sector assignments.
- Each assignment category must have data-defined weekly demand coefficients for each consumer
  good.
- Farm assignments may have lower market demand for clothing and furniture than industrial
  assignments.
- Food demand must apply to the whole represented population, including the population associated
  with farming.
- Delivered final goods must be recorded as satisfied demand. Undelivered quantities must be
  recorded as unmet demand.
- The MVP does not require durable household stocks, preference optimization, income constraints,
  or consumer substitution.

### Planned production

- Every producing sector must use the same generic recipe mechanism.
- A recipe must state its labor requirement, physical input quantities, output quantities, and
  production duration or weekly rate.
- Each regional sector must have finite productive capacity.
- The player must be able to set a production target or target utilization for each sector.
- Actual production must be bounded by productive capacity, assigned labor, and on-hand inputs.
- Inputs must be consumed and outputs created exactly once. The engine must conserve physical
  goods across production, storage, shipment, and final delivery according to the declared recipes.
- Missing inputs must reduce actual output rather than being borrowed from future production.
- A sector trying to satisfy a target must expose the input orders implied by that target. Demand
  must propagate through orders over weekly ticks rather than resolving an entire supply chain
  instantaneously.
- The engine must report target output, feasible output, actual output, and shortfall reasons.

### Sector expansion

- The player must be able to order a capacity upgrade for a regional sector.
- The UI may present standardized capacity increments as sector levels, such as “Primitive
  Furniture Sector — Level 2.”
- The engine must store actual capacity and upgrade progress rather than relying on a hardcoded
  meaning for a level number.
- An upgrade must take a data-defined whole number of weeks and become productive only when
  complete.
- Construction goods, construction labor, financing, and investment efficiency are not required
  for the MVP. Upgrade time is the initial constraint.

### Inventories and orders

- Every physical good must exist in a specific location inventory or a specific in-transit
  shipment.
- Production may use only inventory available at the production location.
- Orders must identify the requested good, quantity, requester, delivery location, and the
  production or final-demand requirement that caused the order.
- Unfilled orders must remain inspectable. The implementation must not silently discard shortages.
- The player must be able to set allocation priorities or shares when multiple destinations
  compete for a scarce inventory.
- Allocation must be deterministic. Capacity left unused by a high-priority destination should be
  available to other eligible demand rather than being wasted solely because of its configured
  share.

### Transportation

- Locations must be connected by data-defined transport routes.
- A route must have a finite weekly transport capacity and a whole-number transit time.
- Barge-sector labor and capacity must bound the transport capacity available on the relevant
  river routes.
- All transported physical goods, including food, must use the same shipment mechanism.
- Starting a shipment must remove its quantity from the origin inventory and create an in-transit
  record.
- In-transit goods must be unavailable for production or consumption.
- A shipment must enter the destination inventory only after its full transit time has elapsed.
- Multiple goods competing for a route must be allocated deterministically according to the
  player's transport priorities or shares.
- The player must be able to inspect queued shipment requests, dispatched shipments, goods in
  transit, expected arrival weeks, and transport capacity that was used or left idle.

### Planned control surface

The public game-core interface must allow a client to:

- Advance the simulation by a weekly tick.
- Pause or refrain from requesting additional ticks.
- Set sector production targets.
- Set target labor assignments.
- Order sector-capacity upgrades.
- Set destination allocations for sector outputs.
- Set priorities or shares for scarce inventories and route capacity.
- Inspect the full economic state required to make those decisions.

Manual controls may eventually be driven by sliders or another graphical interface, but a
graphical UI is not required to validate the economic-model MVP. A headless dev scenario, CLI, or
other thin client may use the same commands and observations.

Future firm intelligence must be able to issue the same commands or planning directives through
the same authoritative game-core interface. The simulation must not depend on whether a directive
came from a human player or a future automated planner.

## Time and determinism requirements

- Simulation time advances only in discrete weekly ticks.
- Commands must have an authoritative order and take effect at a documented weekly phase.
- Production, order creation, shipment departure, shipment arrival, demand fulfillment, labor
  reassignment, and upgrade progress must have a single documented phase order.
- Goods produced during a week must not satisfy an upstream or downstream requirement earlier than
  the documented phase order permits.
- A shipment with a transit time of `N` weeks must arrive after exactly `N` weekly advances from
  departure.
- All gameplay-relevant state, including orders, shipments, allocation directives, labor
  transitions, upgrade progress, and deterministic-generator state, must be serializable.
- Saving and restoring at a stable point must not change subsequent results.
- The same initial state and ordered commands must produce the same state and trace.

## Inspection requirements

At any stable weekly state, clients must be able to inspect:

- Population, available labor, and current and target sector assignments
- Sector capacity, upgrade progress, recipes, targets, actual production, and shortfall reasons
- Inventory by good and location
- Open and filled orders and the demand that caused them
- Shipment queues, route allocation, and in-transit inventory
- Final demand, satisfied demand, and unmet demand by population assignment and good
- A weekly accounting trace explaining all material quantity changes

The trace and observations must be sufficient to distinguish at least these causes of missed
production: insufficient labor, insufficient local input inventory, productive-capacity limits,
goods still in transit, transport-capacity limits, and player allocation choices.

## Acceptance scenarios

The MVP is complete only when deterministic dev scenarios verify all of the following through the
public game-core interface:

1. **Agrarian constraint:** With farm productivity only slightly above food demand per population
   unit, moving too much labor out of farming causes a measurable food shortage.
2. **Industrialization:** Reassigning labor and expanding productive capacity increases clothing
   or furniture production when the required raw materials and transportation are available.
3. **Input propagation:** Final demand creates a final-good requirement, which creates raw-material
   and transport requirements over time without instantaneously resolving the entire chain.
4. **Transport contention:** Two goods competing for insufficient barge capacity are dispatched
   according to player-set priorities, and unused eligible capacity is not stranded.
5. **Transit delay:** Dispatched inventory is unavailable while in transit and arrives on the
   expected week.
6. **Production constraint:** A target above available labor, inputs, or capacity produces the
   feasible amount and reports the correct shortfall.
7. **Conservation:** Goods are neither duplicated nor lost outside declared recipe conversions and
   final delivery.
8. **Replay and restoration:** A saved-and-restored run and a replay of the same commands reach the
   same authoritative state and produce the same trace.

## Explicitly deferred

The following are not part of the economic-model MVP:

- Money, prices, wages, treasuries, credit, profits, and enterprise balance sheets
- Market clearing and price-responsive demand
- Autonomous firms, supplier choice, and autonomous investment
- Agricultural-tool or machinery production and installed capital
- Individual people, households, demographic change, migration, and voluntary employment choice
- Land ownership, rents, enclosure, coercion consequences, unrest, and politics
- Detailed worker skills, occupations, education, and retraining
- Power, fuel, maintenance, spoilage, resource depletion, and seasonal production
- Product quality, substitution, multiple production technologies, and consumer preference models
- Construction-material supply chains and construction-sector labor
- Economic crashes, recessions, banking crises, and endogenous business cycles
- A production graphical UI beyond the public commands and observations needed by interchangeable
  clients

These systems may be added later, but the MVP must not add placeholder behavior for them. Extension
should occur through generic content, additional state, and new decision policies rather than by
replacing the physical production, order, inventory, labor-allocation, and shipment contracts
established here.
