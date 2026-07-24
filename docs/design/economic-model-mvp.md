# Economic model MVP

## Purpose

The first economic-model MVP proves that a small, fully planned physical economy can be controlled,
simulated, saved, replayed, and inspected. It is a foundation for later economic systems, not an
attempt to simulate markets, households, or recessions.

The player acts as the central planner. The player decides what sectors should produce, how labor
should be assigned, and how scarce goods should be allocated. The engine determines what can
actually happen given capacity, inputs, inventories, and labor.

The MVP is successful when the player can industrialize a simple agrarian economy.

## Scope boundary

The MVP models physical quantities only. It has no money, prices, wages, profits, ownership income,
or autonomous investment. Scarcity appears as unmet demand, unfilled orders, idle capacity, and
allocation conflicts.

Population is aggregate. There are no individual people, households, voluntary job choices, or
special peasant agents. A peasant is labor assigned to farming; an industrial worker is labor
assigned to an industrial sector. An unmet food requirement permanently reduces aggregate
population and therefore the economy's total labor capacity. The MVP does not distinguish whether
that loss represents death, emigration, or another cause.

Food is an ordinary good. A farm is an ordinary production sector. The farm itself does not consume
the food allocated to the people working there. If one farm worker produces only slightly more food
than one population unit receives, most labor must remain in agriculture. Giving farms basic tools
can raise their labor productivity and free labor for industry without requiring a special
industrialization rule.

## Required content

The initial scenario must define at least these goods:

- Food
- Wood
- Basic tools
- Furniture

It must define at least these sectors:

| Sector | Required inputs | Output |
| --- | --- | --- |
| Farm | Labor, with optional recurring basic-tool support | Food |
| Logging | Labor | Wood |
| Basic-tool production | Labor and wood | Basic tools |
| Furniture manufacturing | Labor and wood | Furniture |

Basic tools must be allocatable to farms as a recurring weekly support input. Tools supplied to a
farm are consumed that week, and the farm's food output per unit of labor must increase according
to a data-defined rule. Basic tools must also be consumable by sector-capacity upgrades.

Goods, sectors, recipes, labor-efficiency coefficients, and capacities must be content data rather
than engine code dedicated to food, wood, basic tools, or furniture.

## Functional requirements

### Population and labor

- The simulation must track aggregate total population and its assignment among production sectors,
  active construction projects, and an unassigned pool.
- Each production must have a data-defined labor-efficiency coefficient. The coefficient converts
  assigned population into effective labor and includes factors such as the share of the population
  that initially performs productive work and time lost because of poor housing or access to work.
- Population cannot be assigned to more than one production or construction use in the same week.
- The player must be able to set target labor assignments among production sectors, active
  construction projects, and the unassigned pool directly.
- Actual assignments must move toward the targets at a configurable maximum weekly reassignment
  rate. Command authority removes worker choice, but it does not remove administrative delay.
- The engine must report current assignment, target assignment, reassignment in progress, and any
  target that cannot be filled.
- When population falls, the loss must be applied deterministically to the population groups that
  did not receive their food requirement. Current assignments must fall with those groups; labor
  targets remain directives and may consequently become unfillable.

### Final demand

- Every population unit must create the same data-defined baseline food requirement each week,
  regardless of its assignment. The requirement is mandatory rather than chosen by the player.
- The central planner must be able to allocate available food among population grouped by current
  assignment, including unassigned population.
- At the end of the documented weekly phase, an unmet food requirement must permanently reduce the
  affected group's population according to a data-defined rule. The loss must reduce aggregate
  population and future labor capacity; the MVP does not model recovery of lost population.
- The central planner must be able to set desired allocations of other consumer goods to sectors.
- Goods allocated to the people assigned to a sector may improve that production's labor-efficiency
  coefficient according to data-defined rules. This represents effects such as workers spending
  less time providing for themselves or losing less time because of poor living and working
  conditions.
- The food required per population unit must not vary based on whether population is assigned to
  farming, logging, factory work, construction, or no work.
- Food must use the same planned allocation mechanism as other consumer goods.
- Supplied allocations must be recorded as satisfied demand. Unsupplied quantities must be recorded
  as unmet demand.
- The MVP does not require durable household stocks, preference optimization, income constraints,
  or consumer substitution.

### Planned production

- Every producing sector must use the same generic recipe mechanism.
- A recipe must state its labor requirement, physical input quantities, output quantities, and
  production duration or weekly rate.
- Each sector must have finite productive capacity.
- The player must be able to set a production target or target utilization for each sector.
- Actual production must be bounded by productive capacity, assigned labor, and on-hand inputs.
- Inputs must be consumed and outputs created exactly once. The engine must conserve physical
  goods across production, storage, allocation, and final consumption according to the declared
  recipes.
- Missing inputs must reduce actual output rather than being borrowed from future production.
- A sector trying to satisfy a target must expose the input orders implied by that target. Demand
  must propagate through orders over weekly ticks rather than resolving an entire supply chain
  instantaneously.

### Sector expansion

- The player must be able to order a capacity upgrade for a sector.
- The UI may present standardized capacity increments as Factory levels, such as “Primitive
  Furniture Factory — Level 2.”
- The engine must store actual capacity and upgrade progress rather than relying on a hardcoded
  meaning for a level number.
- Each upgrade must have data-defined total labor and basic-tool requirements.
- The player must be able to allocate population and basic tools to an active upgrade each week.
  Construction labor cannot simultaneously work in a production sector, and supplied tools are
  consumed exactly once as progress is recorded.
- An upgrade must record cumulative labor and tool progress and become productive only when both
  requirements are complete. The initial scenario must tune those requirements so an upgrade takes
  multiple weeks and requires a meaningful diversion of labor and tools from current production.
- A separate construction sector, specialized construction materials, financing, and investment
  efficiency are not required for the MVP.

### Inventories and orders

- The simulation must track the aggregate available inventory of every physical good.
- Orders must identify the requested good, quantity, requester, and the production or final-demand
  requirement that caused the order.
- Unfilled orders must remain inspectable. The implementation must not silently discard shortages.
- The player must be able to set allocation priorities or shares when multiple uses compete for a
  scarce inventory.
- Farm support and construction must compete through this allocation mechanism when both request
  scarce basic tools.
- Allocation must be deterministic. Capacity left unused by a high-priority use should be
  available to other eligible demand rather than being wasted solely because of its configured
  share.

### Goods availability

- Goods must become available to their allocated use instantly. The MVP has no separate
  transportation state or delay.
- The labor cost of transporting inputs and outputs must be implicit in each production's labor
  requirement or labor-efficiency coefficient.

### Planned control surface

The public game-core interface must allow a client to:

- Advance the simulation by a weekly tick.
- Pause or refrain from requesting additional ticks.
- Set sector production targets.
- Set target labor assignments among production sectors, construction projects, and the unassigned
  pool.
- Order sector-capacity upgrades.
- Allocate goods among production support, construction, and final uses.
- Set priorities or shares for scarce inventories.
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
- Production, order creation, goods allocation, demand fulfillment, food-shortfall population loss,
  labor reassignment, and upgrade progress must have a single documented phase order.
- Goods produced during a week must not satisfy an upstream or downstream requirement earlier than
  the documented phase order permits.
- All gameplay-relevant state, including population by assignment, orders, allocation directives,
  labor transitions, upgrade progress, and deterministic-generator state, must be serializable.
- Saving and restoring at a stable point must not change subsequent results.
- The same initial state and ordered commands must produce the same state and trace.

## Inspection requirements

At any stable weekly state, clients must be able to inspect:

- Population, weekly population loss, current and target assignments, and labor-efficiency
  coefficients
- Sector capacity, upgrade labor and tool progress, recipes, targets, and actual production
- Aggregate inventory by good
- Open and filled orders and the demand that caused them
- Planned consumer-goods allocations and their effects on labor efficiency
- Final demand, satisfied demand, and unmet demand by good
- A weekly accounting trace explaining all material quantity changes

## Acceptance scenarios

The MVP is complete only when deterministic dev scenarios verify all of the following through the
public game-core interface:

1. **Agrarian constraint:** With farm productivity only slightly above food demand per population
   unit, moving too much labor out of farming causes a measurable food shortage and a permanent,
   deterministic reduction in aggregate population and labor capacity.
2. **Industrialization:** Reassigning labor and expanding productive capacity increases basic-tool
   or furniture production when the required wood is available. An expansion completes only after
   receiving its full labor and basic-tool requirements over multiple weeks.
3. **Input propagation:** Final demand creates a final-good requirement, which creates raw-material
   requirements over time without instantaneously resolving the entire chain.
4. **Basic tools:** Allocating basic tools to farms consumes those tools each week and increases
   food output from the same labor assignment according to the configured productivity rule.
5. **Production constraint:** Production remains bounded by assigned labor, inputs, and capacity.
6. **Conservation:** Goods are neither duplicated nor lost outside declared recipe conversions and
   final delivery, recurring farm support, and construction progress.
7. **Replay and restoration:** A saved-and-restored run and a replay of the same commands reach the
   same authoritative state and produce the same trace.
8. **Competing tool uses:** When farms and construction request more basic tools than are available,
   the configured allocation rule deterministically divides the tools and both uses expose their
   resulting output or progress.

## Explicitly deferred

The following are not part of the economic-model MVP:

- Money, prices, wages, treasuries, credit, profits, and enterprise balance sheets
- Market clearing and price-responsive demand
- Autonomous firms, supplier choice, and autonomous investment
- Advanced agricultural machinery and autonomous capital investment
- Individual people, households, births, aging, explicit migration flows, and voluntary employment
  choice
- Land ownership, rents, enclosure, coercion consequences, unrest, and politics
- Detailed worker skills, occupations, education, and retraining
- Power, fuel, maintenance, spoilage, resource depletion, and seasonal production
- Product quality, substitution, multiple production technologies, and consumer preference models
- Specialized construction-material supply chains and a separate construction sector
- Economic crashes, recessions, banking crises, and endogenous business cycles
- A production graphical UI beyond the public commands and observations needed by interchangeable
  clients

These systems may be added later, but the MVP must not add placeholder behavior for them. Extension
should occur through generic content, additional state, and new decision policies rather than by
replacing the physical production, order, inventory, labor-allocation, and goods-allocation
contracts established here.
