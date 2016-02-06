import React from 'react';

export default function Cell(props) {
  let classes = 'cell ' + (props.alive ? 'alive' : 'dead');
  let pos = {
    top: props.y * 10,
    left: props.x * 10
  }


  return <div className={classes} style={pos}></div>
}
