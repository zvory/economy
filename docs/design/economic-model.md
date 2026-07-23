# Economic model

The economy must behave as a system with memory, limited adjustment speed, and interacting
constraints. Moving a budget slider changes demand and incentives immediately; it does not
instantly move workers, skills, equipment, infrastructure, or supply chains.

The model should be detailed enough to make economic policy choices legible and consequential, but
not so detailed that the player needs professional economics training to understand cause and
effect. It should favor a smaller number of visible, explainable mechanisms over realism produced
by opaque complexity.

## Sectors and production

Each sector has at least:

- productive capacity;
- employed workers and the skills they can currently use;
- available inputs and infrastructure;
- demand for its output;
- productivity; and
- a financial condition or other measure of whether producers can continue operating and
  investing.

Output is limited by the scarcest relevant constraint, not funding alone. Additional demand or
subsidy can increase production only as quickly as the sector can hire and train workers, obtain
inputs, add equipment, and complete projects.

Idle capacity may be restarted faster than new capacity can be built, but it should deteriorate if
left unused. New capacity requires time and investment and should not become fully productive the
moment it is funded.

## Labor adjustment

Workers are not interchangeable units. When a sector contracts, its former workers do not
automatically become productive workers in another sector on the next turn.

Moving between sectors can involve:

- a period of unemployment or reduced employment;
- retraining time and cost;
- geographic relocation;
- loss of sector-specific experience;
- a mismatch between available workers and open jobs; and
- a ramp-up period before workers reach normal productivity.

Some transitions should be easier than others because skills are partly transferable. The model
does not need to simulate individual résumés, but it must preserve enough skill and location
structure for transition costs to matter.

## Expansion, bottlenecks, and waste

Rapidly increasing funding or demand in a sector should have diminishing short-term returns.
Spending beyond the sector's ability to absorb it can cause:

- higher wages and input prices without proportional output;
- rushed procurement and poor project selection;
- shortages displaced into connected sectors;
- construction or delivery delays;
- lower marginal productivity; and
- fraud, leakage, or administrative waste.

Waste should not be a fixed penalty for large budgets. It should depend on the size and speed of
the change relative to existing administrative, labor, input, and productive capacity. Sustained,
well-planned investment can expand those limits over time.

## Contraction and scarring

Abruptly removing support from a sector can close firms, cancel projects, strand specialized
capital, break supplier relationships, and create unemployment. A later restoration of the same
nominal funding should therefore not necessarily restore the sector immediately or at the same
cost.

Temporary downturns can leave persistent scars through lost skills, deferred maintenance,
bankruptcies, reduced investment, and population movement. Gradual, anticipated changes should
generally be less destructive than unexpected cuts of the same total size.

## Recessions and crashes

Recessions and economic crashes should emerge from the ordinary model rather than exist only as
arbitrary events. A shock or policy mistake can propagate through feedback loops such as:

1. A fall in demand reduces production, employment, and income.
2. Lower income causes demand to fall in other sectors.
3. Business failures and loan losses reduce credit and investment.
4. Falling tax receipts and rising support costs strain the public budget.
5. Cuts, shortages, inflation, or loss of confidence amplify the original contraction.

Supply shocks can produce a different crisis: shortages raise prices, reduce real incomes, and
constrain downstream production even while nominal spending rises. Financial distress, excessive
debt, asset-price reversals, trade disruption, and critical infrastructure failure may also start
or amplify a crash if those systems are represented.

A crash is therefore a severe, self-reinforcing loss of output and capacity, not simply a large
negative modifier. Recovery requires breaking the relevant feedback loops and rebuilding damaged
capacity, employment matches, credit, infrastructure, or confidence. Different causes should call
for different remedies.

The simulation must also permit stabilization. Automatic stabilizers, emergency spending,
liquidity or credit support, retraining, maintenance, and credible gradual policy can limit a
downturn, but each intervention should have costs, delays, capacity limits, and possible side
effects.

## Player-facing explanation

The player should be able to inspect why output, employment, prices, and public finances changed.
Forecasts and post-turn explanations should identify the dominant constraints and feedback loops,
for example:

- rail output is limited by trained labor, so most new funding is raising costs this year;
- rail layoffs increased unemployment, but manufacturing cannot absorb those workers until they
  retrain;
- factory output fell because rail capacity disrupted input deliveries; or
- falling household income is now spreading the initial rail contraction into consumer sectors.

Consequences should be forecast as ranges or directional risks when uncertainty matters. The game
should not promise exact outcomes that the player could not reasonably know, but it must expose
enough causal information for players to learn from decisions rather than guess at hidden rules.

## Simulation requirements

- Economic state transitions must follow the deterministic and serializable contracts in
  [Architecture](architecture.md).
- Adjustment delays, capacity limits, and cross-sector dependencies are authoritative game state.
- Policies must distinguish stocks from flows: funding this turn, existing capital, trained labor,
  debt, inventories, and unfinished projects cannot be collapsed into one number.
- Nominal money and real resources must be distinct so that more spending can raise prices rather
  than output when the economy is capacity-constrained.
- The model should support controlled scenarios for a sudden sector cut, an attempted rapid
  expansion, a demand-led recession, and a supply-led crisis.
- Tuning values and sector definitions should be data-driven where practical.

## Decisions still open

- Turn length and the time scale of hiring, training, construction, bankruptcy, and recovery.
- Sector granularity and which skills, inputs, regions, firms, households, banks, trade flows, and
  financial assets are represented explicitly.
- The exact production, price, wage, investment, credit, and expectation mechanisms.
- How government budgets, taxation, borrowing, interest, inflation, and monetary institutions
  interact.
- Whether confidence is modeled directly or only through observable causes such as income,
  solvency, inventories, prices, and policy credibility.
- How much uncertainty forecasts expose and how economic explanations are presented.
- What qualifies as a recession or crash for objectives, events, statistics, and player feedback.
