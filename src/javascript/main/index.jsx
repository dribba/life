import React from 'react';
import ReactDOM from 'react-dom';
import R from 'ramda';
import Cell from './Cell.jsx';

//+ _makeGrid :: Int -> Int -> ((Int, Int) -> a) -> Array (Array a)
const _makeGrid = R.curry((x, y, builder) => {
  let grid = [];

  for(let i = 0; i < x; i++) {
    grid[i] = [];
    for (let j = 0; j < y; j++) {
      grid[i][j] = builder(i, j);
    }
  }

  return grid;
});
const allDead = (x, y) => {
  return {alive: 0, x, y};
};

const allAlive = (x, y) => {
  return {alive: 1, x, y};
};

const allRandom = (x, y) => {
  let alive = Math.random() >= 0.5;
  return {alive: +alive, x, y};
};

const theGrid = _makeGrid(50, 50, allRandom);

function renderGrid(render, grid) {
  const renderRow = R.map(render);
  const renderColumns = R.map(renderRow);

  return renderColumns(grid);
}

function noop() {};

function renderCell(state) {
  return (
    <Cell
      x={state.x}
      y={state.y}
      alive={state.alive}
      key={`${state.x}-${state.y}`} />
  );
}

const Main = () => {
  let cells = renderGrid(renderCell, theGrid);

  return (
    <div id="main-container">
      <div id="game-container">{cells}</div>
      <button onClick={noop} type="button">Step</button>
    </div>
  );
}


ReactDOM.render(<Main/>, document.getElementById('main'));
