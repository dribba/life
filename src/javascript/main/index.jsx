import React from 'react';
import ReactDOM from 'react-dom';
import R from 'ramda';

//+ _makeRow :: ((Int, Int) -> a) -> Int -> Int -> Array a
const _makeRow = R.curry((builder, size, colIdx) => {
  return R.times(i => builder(i, colIdx), size)
});
//+ _makeGrid :: Int -> Int -> ((Int, Int) -> a) -> Array (Array a)
const _makeGrid = R.curry((x, y, builder) => {
  return R.times(_makeRow(builder, x), y);
});

const Main = () => {
  let allDead = (x, y) => 0;

  console.log(_makeGrid(7, 7, allDead));

  return <div>Hello world!</div>;
}


ReactDOM.render(<Main/>, document.getElementById('main'));
