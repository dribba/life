export function Cell(props) {
  return <div className={"cell " + props.alive ? "alive" : "dead"}></div>
}
